import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/domain/models/enums.dart';
import 'package:focusguard/domain/models/focus_profile.dart';
import 'package:focusguard/domain/models/focus_session.dart';
import 'package:focusguard/domain/models/override_policy.dart';
import 'package:focusguard/engine/focus_engine.dart';
import 'package:focusguard/platform/platform_bridge.dart';
import 'package:focusguard/domain/models/app_info.dart';

class MockPlatformBridge implements PlatformBridge {
  bool isEnforcementStarted = false;
  bool isEnforcementStopped = false;

  @override
  Future<Map<String, dynamic>> getCapabilities() async =>
      {'platform': 'mock', 'hasMonotonicClock': true};

  @override
  Future<int> getMonotonicElapsedRealtime() async => 10000;

  @override
  Future<int> getBootCount() async => 1;

  @override
  Future<bool> startEnforcement({
    required List<String> blockedPackages,
    required List<String> allowedPackages,
    required String restrictionLevel,
    required int targetElapsedRealtime,
    required int targetWallClock,
    required String profileName,
  }) async {
    isEnforcementStarted = true;
    isEnforcementStopped = false;
    return true;
  }

  @override
  Future<bool> stopEnforcement() async {
    isEnforcementStopped = true;
    isEnforcementStarted = false;
    return true;
  }

  @override
  Future<List<AppInfo>> getInstalledApps() async => [];

  @override
  Future<int> getAppDailyUsage(String packageName) async => 0;

  @override
  Future<bool> requestUsageStatsPermission() async => true;

  @override
  Future<bool> requestOverlayPermission() async => true;

  @override
  Future<bool> requestDndPermission() async => true;

  @override
  Future<bool> requestAccessibilitySettings() async => true;

  @override
  Future<bool> setDndFilter(bool enabled) async => true;
}

void main() {
  late MockPlatformBridge mockBridge;
  late FocusEngine engine;
  int simulatedMonotonicTime = 10000;

  setUp(() {
    mockBridge = MockPlatformBridge();
    simulatedMonotonicTime = 10000;
    engine = FocusEngine(
      platformBridge: mockBridge,
      monotonicTimeProvider: () => simulatedMonotonicTime,
      overridePolicy: const OverridePolicy(
        enabledOverrideTypes: [
          OverrideType.immediate,
          OverrideType.emergency,
          OverrideType.confirmationPhrase,
        ],
        confirmationPhrase: 'I choose to exit',
        requireReason: true,
      ),
    );
  });

  tearDown(() {
    engine.dispose();
  });

  group('Engine: FocusEngine Core Lifecycle', () {
    test('starts focus session immediately when grace period is 0', () async {
      final profile = FocusProfile.defaultPresets.first;

      final session = await engine.startSession(
        profile: profile,
        durationMinutes: 30,
        gracePeriodSeconds: 0,
      );

      expect(session.state, equals(SessionState.active));
      expect(engine.currentState, equals(SessionState.active));
      expect(mockBridge.isEnforcementStarted, isTrue);
      expect(session.totalDurationSeconds, equals(1800));
    });

    test('starts session in gracePeriod state and allows cancellation',
        () async {
      final profile = FocusProfile.defaultPresets.first;

      await engine.startSession(
        profile: profile,
        durationMinutes: 45,
        gracePeriodSeconds: 10,
      );

      expect(engine.currentState, equals(SessionState.gracePeriod));
      expect(engine.hasActiveSession, isTrue);

      // Cancel during grace period
      await engine.cancelDuringGracePeriod();
      expect(engine.currentState, equals(SessionState.idle));
      expect(engine.hasActiveSession, isFalse);
    });

    test('rejects starting another session while one is already active',
        () async {
      final profile = FocusProfile.defaultPresets.first;
      await engine.startSession(
          profile: profile, durationMinutes: 15, gracePeriodSeconds: 0);

      expect(
        () => engine.startSession(profile: profile, durationMinutes: 30),
        throwsStateError,
      );
    });

    test('manages temporary breaks and enforces break quota', () async {
      final profile = FocusProfile.defaultPresets.first;
      await engine.startSession(
          profile: profile, durationMinutes: 60, gracePeriodSeconds: 0);

      // Take break 1
      await engine.startBreak(5);
      expect(engine.currentState, equals(SessionState.onBreak));
      expect(engine.currentSession!.breaksTaken, equals(1));
      expect(mockBridge.isEnforcementStopped, isTrue);

      // Resume
      await engine.resumeFromBreak();
      expect(engine.currentState, equals(SessionState.active));
      expect(mockBridge.isEnforcementStarted, isTrue);

      // Take break 2
      await engine.startBreak(10);
      expect(engine.currentSession!.breaksTaken, equals(2));
      await engine.resumeFromBreak();

      // Exceeding break quota throws StateError
      expect(() => engine.startBreak(5), throwsStateError);
    });

    test('unlocks session via confirmation phrase override', () async {
      final profile = FocusProfile.defaultPresets.first;
      await engine.startSession(
          profile: profile, durationMinutes: 60, gracePeriodSeconds: 0);

      await engine.overrideSession(
        type: OverrideType.confirmationPhrase,
        typedPhrase: 'I choose to exit',
        typedReason: 'Need to reply to urgent message',
      );

      expect(engine.currentState, equals(SessionState.overridden));
      expect(engine.currentSession!.state, equals(SessionState.overridden));
      expect(mockBridge.isEnforcementStopped, isTrue);
    });

    test('emergencyExit immediately terminates restrictions', () async {
      final profile = FocusProfile.defaultPresets.first;
      await engine.startSession(
          profile: profile, durationMinutes: 60, gracePeriodSeconds: 0);

      await engine.emergencyExit();
      expect(engine.currentState, equals(SessionState.overridden));
      expect(mockBridge.isEnforcementStopped, isTrue);
    });

    test('records distraction attempt and updates session statistics',
        () async {
      final profile = FocusProfile.defaultPresets.first;
      await engine.startSession(
          profile: profile, durationMinutes: 60, gracePeriodSeconds: 0);

      expect(engine.currentSession!.distractionAttempts, equals(0));

      engine.recordDistractionAttempt('com.instagram.android');
      expect(engine.currentSession!.distractionAttempts, equals(1));

      engine.recordDistractionAttempt('com.google.android.youtube');
      expect(engine.currentSession!.distractionAttempts, equals(2));
    });

    test('restores interrupted session following reboot/restart', () async {
      const remainingMillis = 1800 * 1000;
      final wallClockTarget =
          DateTime.now().millisecondsSinceEpoch + remainingMillis;

      final savedSession = FocusSession(
        id: 'interrupted_1',
        profileId: 'preset_deep_work',
        profileName: 'Deep Work',
        restrictionStrength: RestrictionStrength.deepFocus,
        totalDurationSeconds: 1800,
        monotonicStartMs: 5000,
        monotonicTargetMs: 5000 + remainingMillis,
        wallClockStartMs: DateTime.now().millisecondsSinceEpoch - 1000,
        wallClockTargetMs: wallClockTarget,
        state: SessionState.active,
      );

      final restored = await engine.restoreInterruptedSession(savedSession);
      expect(restored, isTrue);
      expect(engine.currentState, equals(SessionState.active));
      expect(mockBridge.isEnforcementStarted, isTrue);
    });
  });
}
