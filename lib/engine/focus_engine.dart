import 'dart:async';
import '../core/constants/app_constants.dart';
import '../core/errors/domain_exceptions.dart';
import '../core/security/tamper_detector.dart';
import '../core/utils/monotonic_time.dart';
import '../domain/models/audit_entry.dart';
import '../domain/models/degradation_report.dart';
import '../domain/models/enums.dart';
import '../domain/models/focus_profile.dart';
import '../domain/models/focus_session.dart';
import '../domain/models/override_policy.dart';
import '../domain/state_machine/session_state_machine.dart';
import '../persistence/session_repository.dart';
import '../platform/platform_bridge.dart';
import 'break_manager.dart';
import 'monotonic_timer.dart';
import 'override_coordinator.dart';

/// Master coordinator for FocusGuard sessions, monotonic timing, breaks, and native enforcement.
class FocusEngine {
  final PlatformBridge platformBridge;
  final int Function() getMonotonicNowMs;
  final SessionRepository? _sessionRepository;

  FocusSession? _currentSession;
  FocusProfile? _activeProfile;
  final SessionStateMachine _stateMachine = SessionStateMachine();
  MonotonicCountdownTimer? _countdownTimer;
  late final BreakManager _breakManager;
  late OverrideCoordinator _overrideCoordinator;

  DegradationReport _currentDegradation = DegradationReport.healthy();
  final StreamController<DegradationReport> _degradationController =
      StreamController<DegradationReport>.broadcast();

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
    SessionRepository? sessionRepository,
  })  : getMonotonicNowMs =
            monotonicTimeProvider ?? (() => MonotonicTime.processElapsedMs),
        _sessionRepository = sessionRepository {
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

  DegradationReport get currentDegradation => _currentDegradation;
  bool get isProtectionDegraded => _currentDegradation.isDegraded;
  Stream<DegradationReport> get degradationStream =>
      _degradationController.stream;

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
    _stateMachine.reset();

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
    _activeProfile = profile;
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

  /// Restores session state in memory (for testing and manual state restoration).
  void restoreSession(FocusSession session) {
    _currentSession = session;
    _stateMachine.forceState(session.state);
    _emitSessionUpdate();
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

  /// Performs an atomic, guaranteed idempotent exit transaction:
  /// 1. Verifies not already in an exit transition (prevents double-tap exits and race conditions)
  /// 2. Progresses state: ACTIVE -> OVERRIDE_REQUESTED -> OVERRIDE_VALIDATING
  /// 3. Validates friction policy (phrase, reason, PIN, cooldown, quota)
  ///    - On failure: safely rolls state back to ACTIVE and throws [OverrideValidationException]
  /// 4. Increments daily used quota
  /// 5. Audits override event
  /// 6. Progresses state to ENDING
  /// 7. Tears down platform restrictions via [platformBridge.stopEnforcement]
  /// 8. Cancels countdown timers, grace period timer, and ends break
  /// 9. Persists ended state to SQLite via [SessionRepository]
  /// 10. Progresses state to OVERRIDDEN (ENDED_OVERRIDE)
  /// 11. Emits session update
  Future<bool> endSessionWithOverride({
    required OverrideType type,
    String? typedPhrase,
    String? typedReason,
    String? pin,
  }) async {
    if (_currentSession == null) {
      throw OverrideValidationException.noActiveSession();
    }

    // Double-tap and race condition guard: If already transitioning to exit, safely return false
    if (_stateMachine.currentState.isTransitioningToExit) {
      return false;
    }

    // 1. Transition to OVERRIDE_REQUESTED -> OVERRIDE_VALIDATING
    if (_stateMachine.canTransitionTo(SessionState.overrideRequested)) {
      _stateMachine.transitionTo(SessionState.overrideRequested);
    }
    if (_stateMachine.canTransitionTo(SessionState.overrideValidating)) {
      _stateMachine.transitionTo(SessionState.overrideValidating);
    }

    // 2. Validate friction against configured policy
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
      // Safe rollback to ACTIVE state on validation failure
      if (_stateMachine.canTransitionTo(SessionState.active)) {
        _stateMachine.transitionTo(SessionState.active);
      }
      final msg = validation.errorMessage ?? 'Override rejected';
      if (msg.contains('does not match')) {
        throw OverrideValidationException.phraseMismatch();
      } else if (msg.contains('at least 5 characters')) {
        throw OverrideValidationException.reasonTooShort();
      } else if (msg.contains('Incorrect PIN')) {
        throw OverrideValidationException.incorrectPin();
      } else if (msg.contains('quota')) {
        throw OverrideValidationException.quotaExhausted(
          _overrideCoordinator.policy.usedOverridesToday,
          _overrideCoordinator.policy.maxOverridesPerDay,
        );
      } else {
        throw OverrideValidationException(
          userMessage: msg,
          technicalDetail: msg,
        );
      }
    }

    // 3. Increment daily used overrides count
    final updatedPolicy = _overrideCoordinator.policy.copyWith(
      usedOverridesToday: _overrideCoordinator.policy.usedOverridesToday + 1,
    );
    _overrideCoordinator = OverrideCoordinator(
      policy: updatedPolicy,
      storedPinHash: _overrideCoordinator.storedPinHash,
      storedPinSalt: _overrideCoordinator.storedPinSalt,
    );

    // 4. Audit override
    _emitAudit(
      eventType: 'override',
      description:
          'Session overridden via ${type.name}. Reason: ${typedReason ?? "none"}',
      sessionId: _currentSession?.id,
    );

    // 5. Mark ENDING
    if (_stateMachine.canTransitionTo(SessionState.ending)) {
      _stateMachine.transitionTo(SessionState.ending);
    }

    // 6. Tear down native restrictions and timers
    _gracePeriodTimer?.cancel();
    _countdownTimer?.stop();
    _breakManager.endBreak();
    await platformBridge.stopEnforcement();

    // 7. Persist ended state
    final endedSession = _currentSession!.copyWith(
      state: SessionState.overridden,
      overrideReason: typedReason ?? type.name,
    );
    _currentSession = endedSession;
    if (_sessionRepository != null) {
      try {
        await _sessionRepository.updateSession(endedSession);
      } catch (_) {
        // Tolerant persistence logging; native unblock must never be blocked by DB
      }
    }

    // 8. Mark OVERRIDDEN (ENDED_OVERRIDE)
    if (_stateMachine.canTransitionTo(SessionState.overridden)) {
      _stateMachine.transitionTo(SessionState.overridden);
    }
    _emitSessionUpdate();

    return true;
  }

  /// Unlocks and terminates the session via configured override friction.
  Future<void> overrideSession({
    required OverrideType type,
    String? typedPhrase,
    String? typedReason,
    String? pin,
  }) async {
    await endSessionWithOverride(
      type: type,
      typedPhrase: typedPhrase,
      typedReason: typedReason,
      pin: pin,
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
    if (_stateMachine.canTransitionTo(SessionState.expired)) {
      _stateMachine.transitionTo(SessionState.expired);
    }
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
      if (_sessionRepository != null) {
        try {
          await _sessionRepository.updateSession(_currentSession!);
        } catch (_) {}
      }
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

  /// Evaluates platform enforcement capabilities and updates the degradation state.
  Future<DegradationReport> checkProtectionHealth() async {
    try {
      final caps = await platformBridge.getCapabilities();
      final isAndroid = caps['platform'] == 'android';
      final hasUsage = caps['hasUsageStatsPermission'] == true;
      final hasOverlay = caps['hasOverlayPermission'] == true;
      final isEnforcing = caps['isEnforcementRunning'] == true;

      final missing = <String>[];
      final affected = <String>[];
      final remediation = <String>[];

      if (isAndroid) {
        if (!hasUsage) {
          missing.add('PACKAGE_USAGE_STATS');
          affected.add('Foreground app detection and usage tracking disabled');
          remediation.add(
              'Open Android Settings > Usage Access and enable FocusGuard');
        }
        if (!hasOverlay) {
          missing.add('SYSTEM_ALERT_WINDOW');
          affected.add('Fullscreen block screen overlay barrier disabled');
          remediation.add(
              'Open Android Settings > Display over other apps and enable FocusGuard');
        }
      }

      if (hasActiveSession &&
          !isEnforcing &&
          caps['platform'] != 'mock' &&
          missing.isEmpty) {
        affected.add('Foreground enforcement service is not currently running');
        remediation
            .add('Tap Restore Protection to restart the enforcement service');
      }

      final report = missing.isNotEmpty ||
              (hasActiveSession &&
                  !isEnforcing &&
                  caps['platform'] != 'mock' &&
                  affected.isNotEmpty)
          ? DegradationReport.degraded(
              missingPermissions: missing,
              affectedMechanisms: affected,
              remediationInstructions: remediation,
              timestampMs: DateTime.now().millisecondsSinceEpoch,
            )
          : DegradationReport.healthy();

      if (_currentDegradation.isDegraded != report.isDegraded ||
          _currentDegradation.missingPermissions.length !=
              report.missingPermissions.length) {
        _currentDegradation = report;
        _degradationController.add(report);
        if (report.isDegraded) {
          _emitAudit(
            eventType: 'protection_degraded',
            description:
                'Protection degraded: missing ${report.missingPermissions.join(", ")}',
            sessionId: _currentSession?.id,
          );
        }
      }
      return report;
    } catch (e) {
      final report = DegradationReport.degraded(
        missingPermissions: ['PLATFORM_COMMUNICATION_ERROR'],
        affectedMechanisms: [
          'Platform method channel communication failed: $e'
        ],
        remediationInstructions: ['Restart FocusGuard or check OS permissions'],
      );
      _currentDegradation = report;
      _degradationController.add(report);
      return report;
    }
  }

  /// Explicitly sets or simulates degradation (useful for adversarial testing & recovery).
  void setDegradation(DegradationReport report) {
    _currentDegradation = report;
    _degradationController.add(report);
    if (report.isDegraded) {
      _emitAudit(
        eventType: 'protection_degraded',
        description: 'Protection degraded: ${report.missingPermissions}',
        sessionId: _currentSession?.id,
      );
    }
  }

  /// Evaluates whether [packageName] is currently restricted under active session and profile.
  bool isAppBlocked(String packageName) {
    if (_currentSession == null ||
        _currentSession!.state != SessionState.active) {
      return false;
    }

    // Emergency callers are permanently unblockable by law and design
    const emergencyPackages = [
      'com.android.dialer',
      'com.google.android.dialer',
      'com.samsung.android.dialer',
      'com.apple.mobilephone',
      'com.android.server.telecom',
    ];
    if (emergencyPackages.contains(packageName)) {
      return false;
    }

    if (_activeProfile != null) {
      if (_activeProfile!.allowedPackageNames.contains(packageName)) {
        return false;
      }
      if (_activeProfile!.blockedPackageNames.contains(packageName)) {
        return true;
      }
    }

    return false;
  }

  void dispose() {
    _gracePeriodTimer?.cancel();
    _countdownTimer?.dispose();
    _breakManager.dispose();
    _sessionController.close();
    _tamperController.close();
    _auditController.close();
    _degradationController.close();
  }
}
