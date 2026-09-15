import 'dart:async';
import '../core/constants/app_constants.dart';
import '../core/security/tamper_detector.dart';
import '../core/utils/monotonic_time.dart';
import '../domain/models/audit_entry.dart';
import '../domain/models/enums.dart';
import '../domain/models/focus_profile.dart';
import '../domain/models/focus_session.dart';
import '../domain/models/override_policy.dart';
import '../domain/state_machine/session_state_machine.dart';
import '../platform/platform_bridge.dart';
import 'break_manager.dart';
import 'monotonic_timer.dart';
import 'override_coordinator.dart';

/// Master coordinator for FocusGuard sessions, monotonic timing, breaks, and native enforcement.
class FocusEngine {
  final PlatformBridge platformBridge;
  final int Function() getMonotonicNowMs;

  FocusSession? _currentSession;
  final SessionStateMachine _stateMachine = SessionStateMachine();
  MonotonicCountdownTimer? _countdownTimer;
  late final BreakManager _breakManager;
  late OverrideCoordinator _overrideCoordinator;

  final StreamController<FocusSession?> _sessionController =
      StreamController<FocusSession?>.broadcast();
  final StreamController<TamperCheckResult> _tamperController =
      StreamController<TamperCheckResult>.broadcast();
  final StreamController<AuditEntry> _auditController =
      StreamController<AuditEntry>.broadcast();

  Timer? _gracePeriodTimer;

  FocusEngine({
    required this.platformBridge,
    int Function()? monotonicTimeProvider,
    OverridePolicy? overridePolicy,
  }) : getMonotonicNowMs =
            monotonicTimeProvider ?? (() => MonotonicTime.processElapsedMs) {
    _breakManager = BreakManager(monotonicTimeProvider: getMonotonicNowMs);
    _overrideCoordinator =
        OverrideCoordinator(policy: overridePolicy ?? const OverridePolicy());
  }

  FocusSession? get currentSession => _currentSession;
  SessionState get currentState => _stateMachine.currentState;
  bool get hasActiveSession =>
      _currentSession != null &&
      (_currentSession!.state == SessionState.active ||
          _currentSession!.state == SessionState.gracePeriod ||
          _currentSession!.state == SessionState.onBreak);

  Stream<FocusSession?> get sessionStream => _sessionController.stream;
  Stream<TamperCheckResult> get tamperAlertStream => _tamperController.stream;
  Stream<AuditEntry> get auditStream => _auditController.stream;
  Stream<BreakTickEvent> get breakStream => _breakManager.onBreakTick;
  BreakManager get breakManager => _breakManager;
  OverrideCoordinator get overrideCoordinator => _overrideCoordinator;

  void updateOverridePolicy(OverridePolicy policy,
      {String? pinHash, String? pinSalt}) {
    _overrideCoordinator = OverrideCoordinator(
      policy: policy,
      storedPinHash: pinHash,
      storedPinSalt: pinSalt,
    );
  }

  /// Initiates a new focus session.
  Future<FocusSession> startSession({
    required FocusProfile profile,
    required int durationMinutes,
    int gracePeriodSeconds = AppConstants.defaultGracePeriodSeconds,
  }) async {
    if (hasActiveSession) {
      throw StateError('A focus session is already active');
    }

    final totalSeconds = durationMinutes * 60;
    final nowMonotonic = getMonotonicNowMs();
    final nowWallClock = DateTime.now().millisecondsSinceEpoch;
    final targetMonotonic = nowMonotonic + (totalSeconds * 1000);
    final targetWallClock = nowWallClock + (totalSeconds * 1000);

    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

    final session = FocusSession(
      id: sessionId,
      profileId: profile.id,
      profileName: profile.name,
      restrictionStrength: profile.restrictionStrength,
      totalDurationSeconds: totalSeconds,
      monotonicStartMs: nowMonotonic,
      monotonicTargetMs: targetMonotonic,
      wallClockStartMs: nowWallClock,
      wallClockTargetMs: targetWallClock,
      state: gracePeriodSeconds > 0
          ? SessionState.gracePeriod
          : SessionState.active,
      bootCountAtStart: 0,
      gracePeriodSeconds: gracePeriodSeconds,
    );

    _currentSession = session;
    _stateMachine.transitionTo(session.state);
    _emitSessionUpdate();

    _emitAudit(
      eventType: 'session_start',
      description:
          'Focus session started with profile "${profile.name}" for $durationMinutes min',
      sessionId: sessionId,
    );

    if (gracePeriodSeconds > 0) {
      _gracePeriodTimer = Timer(Duration(seconds: gracePeriodSeconds), () {
        _activateEnforcement(profile);
      });
    } else {
      await _activateEnforcement(profile);
    }

    return session;
  }

  /// Cancels session during the grace period before hard enforcement begins.
  Future<void> cancelDuringGracePeriod() async {
    if (_currentSession == null ||
        _currentSession!.state != SessionState.gracePeriod) {
      throw StateError('Can only cancel during the grace period');
    }

    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = null;

    _stateMachine.transitionTo(SessionState.cancelled);
    _currentSession = _currentSession!.copyWith(state: SessionState.cancelled);
    _emitSessionUpdate();

    _emitAudit(
      eventType: 'session_cancelled',
      description: 'Session cancelled during grace period',
      sessionId: _currentSession?.id,
    );

    _currentSession = null;
    _stateMachine.reset();
    _emitSessionUpdate();
  }

  Future<void> _activateEnforcement(FocusProfile profile) async {
    if (_currentSession == null) return;

    if (_stateMachine.canTransitionTo(SessionState.active)) {
      _stateMachine.transitionTo(SessionState.active);
      _currentSession = _currentSession!.copyWith(state: SessionState.active);
      _emitSessionUpdate();
    }

    // Connect with native platform bridge
    await platformBridge.startEnforcement(
      blockedPackages: profile.blockedPackageNames,
      allowedPackages: profile.allowedPackageNames,
      restrictionLevel: profile.restrictionStrength.name,
      targetElapsedRealtime: _currentSession!.monotonicTargetMs,
      targetWallClock: _currentSession!.wallClockTargetMs,
      profileName: profile.name,
    );

    // Initialize monotonic countdown timer
    _countdownTimer?.dispose();
    _countdownTimer = MonotonicCountdownTimer(
      totalDurationSeconds: _currentSession!.totalDurationSeconds,
      monotonicTargetMs: _currentSession!.monotonicTargetMs,
      wallClockTargetMs: _currentSession!.wallClockTargetMs,
      monotonicTimeProvider: getMonotonicNowMs,
    );

    _countdownTimer!.onTick.listen((event) {
      if (event.tamperAlert != null) {
        _tamperController.add(event.tamperAlert!);
        _emitAudit(
          eventType: 'tamper_alert',
          description: 'Clock discrepancy: ${event.tamperAlert!.reason}',
          sessionId: _currentSession?.id,
        );
      }

      if (event.isFinished) {
        _completeSessionNaturally();
      } else {
        _emitSessionUpdate();
      }
    });

    _countdownTimer!.start();
  }

  /// Starts a temporary break.
  Future<void> startBreak(int durationMinutes) async {
    if (_currentSession == null ||
        _currentSession!.state != SessionState.active) {
      throw StateError('Cannot take a break when session is not active');
    }

    if (_currentSession!.breaksTaken >= _currentSession!.maxBreaksAllowed) {
      throw StateError('Break quota exhausted for this session');
    }

    _countdownTimer?.stop();
    await platformBridge.stopEnforcement();

    _stateMachine.transitionTo(SessionState.onBreak);
    _currentSession = _currentSession!.copyWith(
      state: SessionState.onBreak,
      breaksTaken: _currentSession!.breaksTaken + 1,
    );
    _emitSessionUpdate();

    _emitAudit(
      eventType: 'break_start',
      description: 'Temporary break started for $durationMinutes minutes',
      sessionId: _currentSession?.id,
    );

    _breakManager.startBreak(
      durationMinutes: durationMinutes,
      onBreakExpired: () {
        resumeFromBreak();
      },
    );
  }

  /// Resumes focus session after a break.
  Future<void> resumeFromBreak() async {
    if (_currentSession == null ||
        _currentSession!.state != SessionState.onBreak) {
      return;
    }

    _breakManager.endBreak();

    if (_stateMachine.canTransitionTo(SessionState.active)) {
      _stateMachine.transitionTo(SessionState.active);
      _currentSession = _currentSession!.copyWith(state: SessionState.active);
      _emitSessionUpdate();

      _emitAudit(
        eventType: 'break_end',
        description: 'Focus resumed following temporary break',
        sessionId: _currentSession?.id,
      );

      // Re-enable platform enforcement
      await platformBridge.startEnforcement(
        blockedPackages: [],
        allowedPackages: [],
        restrictionLevel: _currentSession!.restrictionStrength.name,
        targetElapsedRealtime: _currentSession!.monotonicTargetMs,
        targetWallClock: _currentSession!.wallClockTargetMs,
        profileName: _currentSession!.profileName,
      );

      _countdownTimer?.start();
    }
  }

  /// Unlocks and terminates the session via configured override friction.
  Future<void> overrideSession({
    required OverrideType type,
    String? typedPhrase,
    String? typedReason,
    String? pin,
  }) async {
    if (_currentSession == null) {
      throw StateError('No active session to override');
    }

    OverrideValidationResult validation;
    switch (type) {
      case OverrideType.immediate:
        validation = _overrideCoordinator.validateImmediateOverride();
        break;
      case OverrideType.emergency:
        validation = _overrideCoordinator.validateEmergencyOverride();
        break;
      case OverrideType.typedReason:
        validation = (typedReason != null && typedReason.trim().length >= 5)
            ? OverrideValidationResult.success(OverrideType.typedReason)
            : OverrideValidationResult.failure(
                OverrideType.typedReason,
                'A typed explanation of at least 5 characters is required',
              );
        break;
      case OverrideType.confirmationPhrase:
        validation = _overrideCoordinator.validateConfirmationPhrase(
          candidatePhrase: typedPhrase ?? '',
          reason: typedReason,
        );
        break;
      case OverrideType.pinProtected:
        validation = _overrideCoordinator.validatePin(
          candidatePin: pin ?? '',
          reason: typedReason,
        );
        break;
      case OverrideType.delayedCooldown:
        validation =
            OverrideValidationResult.success(OverrideType.delayedCooldown);
        break;
    }

    if (!validation.isSuccessful) {
      throw StateError(validation.errorMessage ?? 'Override rejected');
    }

    await _terminateSession(SessionState.overridden,
        reason: typedReason ?? type.name);

    _emitAudit(
      eventType: 'override',
      description:
          'Session overridden via ${type.name}. Reason: ${typedReason ?? "none"}',
      sessionId: _currentSession?.id,
    );
  }

  /// Instant unblockable emergency exit for calls and safety.
  Future<void> emergencyExit() async {
    await overrideSession(
        type: OverrideType.emergency, typedReason: 'Emergency Access Invoked');
  }

  /// Records an attempted access to a blocked application during active focus.
  void recordDistractionAttempt(String packageName) {
    if (_currentSession == null ||
        _currentSession!.state != SessionState.active) return;

    _currentSession = _currentSession!.copyWith(
      distractionAttempts: _currentSession!.distractionAttempts + 1,
    );
    _emitSessionUpdate();

    _emitAudit(
      eventType: 'distraction_attempt',
      description: 'Attempted to open restricted app: $packageName',
      sessionId: _currentSession?.id,
    );
  }

  Future<void> _completeSessionNaturally() async {
    await _terminateSession(SessionState.completed);
    _emitAudit(
      eventType: 'session_complete',
      description: 'Focus session completed successfully!',
      sessionId: _currentSession?.id,
    );
  }

  Future<void> _terminateSession(SessionState finalState,
      {String? reason}) async {
    _gracePeriodTimer?.cancel();
    _countdownTimer?.stop();
    _breakManager.endBreak();

    await platformBridge.stopEnforcement();

    if (_currentSession != null && _stateMachine.canTransitionTo(finalState)) {
      _stateMachine.transitionTo(finalState);
      _currentSession = _currentSession!.copyWith(
        state: finalState,
        overrideReason: reason,
      );
      _emitSessionUpdate();
    }
  }

  /// Restores session state after device reboot or process recovery.
  Future<bool> restoreInterruptedSession(FocusSession savedSession) async {
    final nowWallClock = DateTime.now().millisecondsSinceEpoch;

    // Check if session has already elapsed while device was off
    if (savedSession.wallClockTargetMs <= nowWallClock) {
      _currentSession = savedSession.copyWith(state: SessionState.completed);
      _stateMachine.forceState(SessionState.completed);
      _emitSessionUpdate();
      return false;
    }

    // Recalculate monotonic target from remaining wall-clock delta
    final remainingMillis = savedSession.wallClockTargetMs - nowWallClock;
    final nowMonotonic = getMonotonicNowMs();
    final newMonotonicTarget = nowMonotonic + remainingMillis;

    _currentSession = savedSession.copyWith(
      monotonicStartMs: nowMonotonic,
      monotonicTargetMs: newMonotonicTarget,
      state: SessionState.active,
    );

    _stateMachine.reset();
    _stateMachine.transitionTo(SessionState.active);
    _emitSessionUpdate();

    _emitAudit(
      eventType: 'session_restored',
      description:
          'Session automatically restored following device/process restart',
      sessionId: _currentSession?.id,
    );

    await platformBridge.startEnforcement(
      blockedPackages: [],
      allowedPackages: [],
      restrictionLevel: _currentSession!.restrictionStrength.name,
      targetElapsedRealtime: newMonotonicTarget,
      targetWallClock: savedSession.wallClockTargetMs,
      profileName: _currentSession!.profileName,
    );

    _countdownTimer?.dispose();
    _countdownTimer = MonotonicCountdownTimer(
      totalDurationSeconds: (remainingMillis / 1000).ceil(),
      monotonicTargetMs: newMonotonicTarget,
      wallClockTargetMs: savedSession.wallClockTargetMs,
      monotonicTimeProvider: getMonotonicNowMs,
    );
    _countdownTimer!.start();

    return true;
  }

  void _emitSessionUpdate() {
    _sessionController.add(_currentSession);
  }

  void _emitAudit(
      {required String eventType,
      required String description,
      String? sessionId}) {
    final entry = AuditEntry(
      id: 'audit_${DateTime.now().microsecondsSinceEpoch}',
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      eventType: eventType,
      description: description,
      sessionId: sessionId,
    );
    _auditController.add(entry);
  }

  void dispose() {
    _gracePeriodTimer?.cancel();
    _countdownTimer?.dispose();
    _breakManager.dispose();
    _sessionController.close();
    _tamperController.close();
    _auditController.close();
  }
}
