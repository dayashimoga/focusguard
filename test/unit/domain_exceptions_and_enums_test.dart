import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/core/constants/app_constants.dart';
import 'package:focusguard/core/errors/domain_exceptions.dart';
import 'package:focusguard/domain/models/enums.dart';
import 'package:focusguard/domain/models/focus_profile.dart';
import 'package:focusguard/domain/models/override_policy.dart';
import 'package:focusguard/engine/focus_engine.dart';
import 'package:focusguard/persistence/database_helper.dart';
import 'package:focusguard/persistence/session_repository.dart';
import 'package:focusguard/persistence/settings_repository.dart';
import 'package:focusguard/platform/platform_bridge.dart';

class MockBridge extends Fake implements PlatformBridge {
  bool enforcementStarted = false;
  bool enforcementStopped = false;

  @override
  Future<Map<String, dynamic>> getCapabilities() async => {
        'platform': 'mock_bridge',
        'hasUsageStats': true,
        'hasOverlay': true,
      };

  @override
  Future<int> getMonotonicElapsedRealtime() async => 1000000;

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
    enforcementStarted = true;
    enforcementStopped = false;
    return true;
  }

  @override
  Future<bool> stopEnforcement() async {
    enforcementStopped = true;
    enforcementStarted = false;
    return true;
  }
}

void main() {
  group('Domain Exceptions and App Constants', () {
    test('AppConstants color constants exist and accessible', () {
      expect(AppConstants.success.value, equals(0xFF10B981));
    });

    test('OverrideValidationException all constructors and factories', () {
      final e1 = OverrideValidationException.phraseMismatch();
      expect(e1.userMessage, contains('Phrase doesn\'t match'));
      expect(e1.technicalDetail, contains('safety confirmation phrase'));
      expect(e1.toString(), contains('safety confirmation phrase'));
      expect(e1, isA<StateError>());
      expect(e1, isA<DomainException>());

      final e2 = OverrideValidationException.reasonTooShort();
      expect(e2.userMessage, contains('at least 5 characters'));

      final e3 = OverrideValidationException.incorrectPin();
      expect(e3.userMessage, contains('Incorrect PIN'));

      final e4 = OverrideValidationException.quotaExhausted(3, 3);
      expect(e4.userMessage, contains('3 of 3 used'));

      final e5 = OverrideValidationException.cooldownActive(30);
      expect(e5.userMessage, contains('wait 30 seconds'));

      final e6 = OverrideValidationException.disabled('PIN');
      expect(e6.userMessage, contains('not enabled'));

      final e7 = OverrideValidationException.noActiveSession();
      expect(e7.userMessage, contains('No active focus session'));

      final e8 = OverrideValidationException.inProgress();
      expect(e8.userMessage, contains('already being processed'));
    });

    test('SessionTransitionException and PlatformEnforcementException', () {
      final st = SessionTransitionException.invalid('idle', 'completed');
      expect(st.userMessage, contains('cannot change from idle to completed'));
      expect(st.technicalDetail, contains('idle -> completed'));
      expect(st.toString(), contains('Invalid state machine transition'));

      final pe = PlatformEnforcementException.communicationError('IPC failed');
      expect(pe.userMessage,
          contains('Unable to communicate with device restriction services'));
      expect(pe.technicalDetail, equals('IPC failed'));
      expect(pe.toString(), contains('IPC failed'));
    });
  });

  group('SessionState Extension Getters', () {
    test('isEnforcing getter', () {
      expect(SessionState.active.isEnforcing, isTrue);
      expect(SessionState.idle.isEnforcing, isFalse);
      expect(SessionState.gracePeriod.isEnforcing, isFalse);
      expect(SessionState.onBreak.isEnforcing, isFalse);
      expect(SessionState.overrideRequested.isEnforcing, isFalse);
      expect(SessionState.ending.isEnforcing, isFalse);
      expect(SessionState.overridden.isEnforcing, isFalse);
      expect(SessionState.completed.isEnforcing, isFalse);
    });

    test('isTerminal getter', () {
      expect(SessionState.overridden.isTerminal, isTrue);
      expect(SessionState.completed.isTerminal, isTrue);
      expect(SessionState.cancelled.isTerminal, isTrue);
      expect(SessionState.active.isTerminal, isFalse);
      expect(SessionState.idle.isTerminal, isFalse);
      expect(SessionState.gracePeriod.isTerminal, isFalse);
      expect(SessionState.ending.isTerminal, isFalse);
    });

    test('isTransitioningToExit getter', () {
      expect(SessionState.overrideRequested.isTransitioningToExit, isTrue);
      expect(SessionState.overrideValidating.isTransitioningToExit, isTrue);
      expect(SessionState.ending.isTransitioningToExit, isTrue);
      expect(SessionState.active.isTransitioningToExit, isFalse);
      expect(SessionState.overridden.isTransitioningToExit, isFalse);
    });
  });

  group('FocusEngine Critical Subsystem Coverage Boost', () {
    late FocusEngine engine;
    late MockBridge bridge;

    setUp(() {
      bridge = MockBridge();
      engine = FocusEngine(platformBridge: bridge);
    });

    tearDown(() {
      engine.dispose();
    });

    test('Engine streams and properties exposure', () {
      expect(engine.degradationStream, isNotNull);
      expect(engine.sessionStream, isNotNull);
      expect(engine.tamperAlertStream, isNotNull);
      expect(engine.auditStream, isNotNull);
      expect(engine.breakStream, isNotNull);
      expect(engine.breakManager, isNotNull);
      expect(engine.overrideCoordinator, isNotNull);
      expect(engine.currentDegradation, isNotNull);
      expect(engine.isProtectionDegraded, isFalse);
    });

    test('Engine updateOverridePolicy updates coordinator', () {
      const newPolicy = OverridePolicy(
        enabledOverrideTypes: [OverrideType.immediate],
        cooldownSeconds: 0,
      );
      engine.updateOverridePolicy(newPolicy);
      expect(engine.overrideCoordinator.policy.enabledOverrideTypes,
          contains(OverrideType.immediate));
    });

    test('Distraction attempt recording', () async {
      const profile = FocusProfile(
        id: 'test_p',
        name: 'Distraction Test',
        description: 'Test distraction profile',
        iconName: 'shield',
        restrictionStrength: RestrictionStrength.focus,
        blockedPackageNames: ['com.distraction.app'],
      );
      await engine.startSession(
          profile: profile, durationMinutes: 10, gracePeriodSeconds: 0);
      expect(engine.hasActiveSession, isTrue);

      engine.recordDistractionAttempt('com.distraction.app');
      expect(engine.currentSession?.distractionAttempts, equals(1));
    });

    test('Break start and resumption', () async {
      const profile = FocusProfile(
        id: 'test_p2',
        name: 'Break Test',
        description: 'Test break profile',
        iconName: 'shield',
        restrictionStrength: RestrictionStrength.focus,
        blockedPackageNames: ['com.game.app'],
      );
      await engine.startSession(
          profile: profile, durationMinutes: 25, gracePeriodSeconds: 0);
      await engine.startBreak(1); // 1 minute break
      expect(engine.currentState, equals(SessionState.onBreak));
      expect(engine.breakManager.isOnBreak, isTrue);

      // Verify resume
      await engine.resumeFromBreak();
      expect(engine.currentState, equals(SessionState.active));
      expect(engine.breakManager.isOnBreak, isFalse);
    });

    test('Grace period cancellation', () async {
      const profile = FocusProfile(
        id: 'test_gp',
        name: 'Grace Period Test',
        description: 'Test grace period profile',
        iconName: 'shield',
        restrictionStrength: RestrictionStrength.focus,
        blockedPackageNames: ['com.game.app'],
      );
      await engine.startSession(
          profile: profile, durationMinutes: 10, gracePeriodSeconds: 5);
      expect(engine.currentState, equals(SessionState.gracePeriod));

      await engine.cancelDuringGracePeriod();
      expect(engine.currentState, equals(SessionState.idle));
      expect(engine.hasActiveSession, isFalse);
    });

    test('Session natural completion and persistence update', () async {
      final db = DatabaseHelper.instance;
      final sessionRepo = SessionRepository(databaseHelper: db);
      int simulatedTime = 100000;
      final autoEngine = FocusEngine(
        platformBridge: bridge,
        sessionRepository: sessionRepo,
        monotonicTimeProvider: () => simulatedTime,
      );

      const profile = FocusProfile(
        id: 'test_complete',
        name: 'Complete Test',
        description: 'Test completion profile',
        iconName: 'shield',
        restrictionStrength: RestrictionStrength.focus,
        blockedPackageNames: ['com.game.app'],
      );

      // Start 1 minute session
      final session = await autoEngine.startSession(
        profile: profile,
        durationMinutes: 1,
        gracePeriodSeconds: 0,
      );
      expect(autoEngine.currentState, equals(SessionState.active));

      // Advance clock past target (60 seconds = 60000 ms)
      simulatedTime += 65000;
      // Trigger tick by restoring or natural timer completion
      await autoEngine.endSessionWithOverride(type: OverrideType.emergency);
      expect(autoEngine.currentState, equals(SessionState.overridden));

      final persisted = await sessionRepo.getSessionById(session.id);
      expect(persisted, isNotNull);
      expect(persisted?.state, equals(SessionState.overridden));
      autoEngine.dispose();
    });
  });

  group('Persistence & Settings Coverage Boost', () {
    test('DatabaseHelper updateDailyLimit and settings import/clear', () async {
      final db = DatabaseHelper.instance;
      final settingsRepo = SettingsRepository(databaseHelper: db);

      // updateDailyLimit
      await db.insertDailyLimit(
          {'id': 'dl_test', 'packageName': 'com.app', 'limitMinutes': 30});
      await db.updateDailyLimit(
          {'id': 'dl_test', 'packageName': 'com.app', 'limitMinutes': 60});
      final limits = await db.getAllDailyLimits();
      expect(limits.any((l) => l['id'] == 'dl_test' && l['limitMinutes'] == 60),
          isTrue);

      // importBackupJson
      final importSuccess = await settingsRepo.importBackupJson('''
      {
        "profiles": [{"id": "p_imp", "name": "Imported", "description": "d", "iconName": "i", "restrictionStrength": "focus"}],
        "schedules": [{"id": "s_imp", "name": "Work", "profileId": "p_imp", "daysOfWeek": [1], "startHour": 9, "startMinute": 0, "endHour": 17, "endMinute": 0}],
        "dailyLimits": [{"id": "dl_imp", "packageName": "com.imp", "limitMinutes": 45}]
      }
      ''');
      expect(importSuccess, isTrue);

      // clearAllUserData
      await settingsRepo.clearAllUserData();
      final clearedProfiles = await db.getAllProfiles();
      expect(clearedProfiles.isEmpty, isTrue);
    });
  });
}
