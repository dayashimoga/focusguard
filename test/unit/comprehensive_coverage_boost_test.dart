import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/core/security/pin_hasher.dart';
import 'package:focusguard/domain/models/app_info.dart';
import 'package:focusguard/domain/models/audit_entry.dart';
import 'package:focusguard/domain/models/enums.dart';
import 'package:focusguard/domain/models/focus_profile.dart';
import 'package:focusguard/domain/models/focus_schedule.dart';
import 'package:focusguard/domain/models/focus_session.dart';
import 'package:focusguard/domain/models/override_policy.dart';
import 'package:focusguard/engine/focus_engine.dart';
import 'package:focusguard/engine/override_coordinator.dart';
import 'package:focusguard/persistence/audit_repository.dart';
import 'package:focusguard/persistence/database_helper.dart';
import 'package:focusguard/persistence/profile_repository.dart';
import 'package:focusguard/persistence/schedule_repository.dart';
import 'package:focusguard/persistence/session_repository.dart';
import 'package:focusguard/platform/platform_bridge.dart';

class TestMockBridge extends Fake implements PlatformBridge {
  Map<String, dynamic> caps = {'platform': 'mock'};
  bool throwOnCaps = false;

  @override
  Future<Map<String, dynamic>> getCapabilities() async {
    if (throwOnCaps) throw Exception('Simulated IPC failure');
    return caps;
  }

  @override
  Future<int> getMonotonicElapsedRealtime() async => 100000;

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
  }) async =>
      true;

  @override
  Future<bool> stopEnforcement() async => true;

  @override
  Future<List<AppInfo>> getInstalledApps() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestMockBridge bridge;
  late FocusEngine engine;
  int mockTime = 100000;

  setUp(() {
    mockTime = 100000;
    bridge = TestMockBridge();
    engine = FocusEngine(
      platformBridge: bridge,
      monotonicTimeProvider: () => mockTime,
      overridePolicy: const OverridePolicy(
        enabledOverrideTypes: [
          OverrideType.immediate,
          OverrideType.emergency,
          OverrideType.typedReason,
          OverrideType.confirmationPhrase,
          OverrideType.pinProtected,
          OverrideType.delayedCooldown,
        ],
        maxOverridesPerDay: 5,
        usedOverridesToday: 0,
        cooldownSeconds: 1,
        confirmationPhrase: 'I confirm exit',
      ),
    );
  });

  tearDown(() {
    engine.dispose();
  });

  group('FocusEngine Comprehensive Unit Coverage', () {
    test('cancelDuringGracePeriod error conditions and success', () async {
      // 1. Error when no session active
      expect(() => engine.cancelDuringGracePeriod(), throwsStateError);

      // 2. Start session with grace period
      final session = await engine.startSession(
        profile: FocusProfile.defaultPresets.first,
        durationMinutes: 25,
        gracePeriodSeconds: 30,
      );
      expect(session.state, equals(SessionState.gracePeriod));
      expect(engine.currentState, equals(SessionState.gracePeriod));

      // 3. Cancel during grace period successfully
      await engine.cancelDuringGracePeriod();
      expect(engine.currentSession, isNull);
      expect(engine.currentState, equals(SessionState.idle));
      expect(engine.hasActiveSession, isFalse);

      // 4. Cannot cancel after session is active (not grace period)
      await engine.startSession(
        profile: FocusProfile.defaultPresets.first,
        durationMinutes: 25,
        gracePeriodSeconds: 0,
      );
      expect(engine.currentState, equals(SessionState.active));
      expect(() => engine.cancelDuringGracePeriod(), throwsStateError);
    });

    test('startBreak and resumeFromBreak edge validations', () async {
      // 1. Cannot break when idle
      expect(() => engine.startBreak(5), throwsStateError);

      await engine.startSession(
        profile: FocusProfile.defaultPresets.first,
        durationMinutes: 25,
        gracePeriodSeconds: 0,
      );

      // 2. Break successfully
      await engine.startBreak(5);
      expect(engine.currentState, equals(SessionState.onBreak));

      // 3. Resume from break
      await engine.resumeFromBreak();
      expect(engine.currentState, equals(SessionState.active));

      // 4. Calling resumeFromBreak when already active is safe no-op
      await engine.resumeFromBreak();
      expect(engine.currentState, equals(SessionState.active));

      // 5. Test break quota exhaustion
      engine.restoreSession(engine.currentSession!.copyWith(
        breaksTaken: 2,
        maxBreaksAllowed: 2,
        state: SessionState.active,
      ));
      expect(() => engine.startBreak(5), throwsStateError);
    });

    test('overrideSession failure modes and edge cases', () async {
      // 1. No active session throws StateError
      expect(
        () => engine.overrideSession(type: OverrideType.immediate),
        throwsStateError,
      );

      await engine.startSession(
        profile: FocusProfile.defaultPresets.first,
        durationMinutes: 25,
        gracePeriodSeconds: 0,
      );

      // 2. Typed reason validation failure (< 5 chars)
      expect(
        () => engine.overrideSession(
          type: OverrideType.typedReason,
          typedReason: 'bad',
        ),
        throwsStateError,
      );

      // 3. Confirmation phrase mismatch failure
      expect(
        () => engine.overrideSession(
          type: OverrideType.confirmationPhrase,
          typedPhrase: 'wrong phrase',
          typedReason: 'valid reason here',
        ),
        throwsStateError,
      );

      // 4. PIN failure when no pin configured
      expect(
        () => engine.overrideSession(
          type: OverrideType.pinProtected,
          pin: '1234',
        ),
        throwsStateError,
      );

      // 5. Delayed cooldown override validation
      await engine.overrideSession(type: OverrideType.delayedCooldown);
      expect(engine.currentState, equals(SessionState.overridden));
    });

    test('emergencyExit triggers emergency override and terminates session',
        () async {
      await engine.startSession(
        profile: FocusProfile.defaultPresets.first,
        durationMinutes: 25,
        gracePeriodSeconds: 0,
      );

      await engine.emergencyExit();
      expect(engine.currentState, equals(SessionState.overridden));
      expect(engine.currentSession?.overrideReason,
          contains('Emergency Access Invoked'));
    });

    test('recordDistractionAttempt tracking and no-op when inactive', () async {
      // No-op when no session
      engine.recordDistractionAttempt('com.social.app');
      expect(engine.currentSession, isNull);

      await engine.startSession(
        profile: FocusProfile.defaultPresets.first,
        durationMinutes: 25,
        gracePeriodSeconds: 0,
      );

      engine.recordDistractionAttempt('com.social.app');
      expect(engine.currentSession?.distractionAttempts, equals(1));
      engine.recordDistractionAttempt('com.game.app');
      expect(engine.currentSession?.distractionAttempts, equals(2));
    });

    test('restoreInterruptedSession when elapsed vs remaining', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Session already elapsed while offline
      final elapsedSession = FocusSession(
        id: 'session_elapsed',
        profileId: 'default',
        profileName: 'Deep Work',
        restrictionStrength: RestrictionStrength.strict,
        totalDurationSeconds: 1500,
        monotonicStartMs: 50000,
        monotonicTargetMs: 90000,
        wallClockStartMs: now - 3600000,
        wallClockTargetMs: now - 1800000, // in the past!
        state: SessionState.active,
        bootCountAtStart: 1,
      );

      final elapsedResult =
          await engine.restoreInterruptedSession(elapsedSession);
      expect(elapsedResult, isFalse);
      expect(engine.currentState, equals(SessionState.completed));

      // 2. Session still has remaining time
      final remainingSession = FocusSession(
        id: 'session_remaining',
        profileId: 'default',
        profileName: 'Deep Work',
        restrictionStrength: RestrictionStrength.strict,
        totalDurationSeconds: 1500,
        monotonicStartMs: 50000,
        monotonicTargetMs: 90000,
        wallClockStartMs: now - 600000,
        wallClockTargetMs: now + 900000, // 15 min in future!
        state: SessionState.active,
        bootCountAtStart: 1,
      );

      final remainingResult =
          await engine.restoreInterruptedSession(remainingSession);
      expect(remainingResult, isTrue);
      expect(engine.currentState, equals(SessionState.active));
      expect(engine.currentSession?.monotonicTargetMs, greaterThan(mockTime));
    });

    test('checkProtectionHealth Android permissions evaluation and exceptions',
        () async {
      // 1. Android healthy
      bridge.caps = {
        'platform': 'android',
        'hasUsageStatsPermission': true,
        'hasOverlayPermission': true,
        'isEnforcementRunning': false,
      };
      var report = await engine.checkProtectionHealth();
      expect(report.isDegraded, isFalse);

      // 2. Android missing both permissions
      bridge.caps = {
        'platform': 'android',
        'hasUsageStatsPermission': false,
        'hasOverlayPermission': false,
        'isEnforcementRunning': false,
      };
      report = await engine.checkProtectionHealth();
      expect(report.isDegraded, isTrue);
      expect(report.missingPermissions, contains('PACKAGE_USAGE_STATS'));
      expect(report.missingPermissions, contains('SYSTEM_ALERT_WINDOW'));

      // 3. Android active session with enforcement not running
      bridge.caps = {
        'platform': 'android',
        'hasUsageStatsPermission': true,
        'hasOverlayPermission': true,
        'isEnforcementRunning': false,
      };
      await engine.startSession(
        profile: FocusProfile.defaultPresets.first,
        durationMinutes: 25,
        gracePeriodSeconds: 0,
      );
      report = await engine.checkProtectionHealth();
      expect(report.isDegraded, isTrue);
      expect(report.affectedMechanisms.first,
          contains('Foreground enforcement service is not currently running'));

      // 4. Exception catch branch
      bridge.throwOnCaps = true;
      report = await engine.checkProtectionHealth();
      expect(report.isDegraded, isTrue);
      expect(
          report.missingPermissions, contains('PLATFORM_COMMUNICATION_ERROR'));
    });
  });

  group('OverrideCoordinator Edge Scenarios & Streams', () {
    test('cooldown countdown stream completes down to 0', () async {
      const policy = OverridePolicy(
        cooldownSeconds: 1,
        enabledOverrideTypes: [OverrideType.delayedCooldown],
      );
      final coordinator = OverrideCoordinator(policy: policy);

      final ticks = <int>[];
      await for (final val in coordinator.startCooldownStream()) {
        ticks.add(val);
      }
      expect(ticks, equals([1, 0]));
    });

    test('validateImmediateOverride disabled or quota exhausted', () {
      // Disabled
      final coord1 = OverrideCoordinator(
        policy: const OverridePolicy(enabledOverrideTypes: []),
      );
      final res1 = coord1.validateImmediateOverride();
      expect(res1.isSuccessful, isFalse);
      expect(res1.errorMessage, contains('disabled'));

      // Quota exhausted
      final coord2 = OverrideCoordinator(
        policy: const OverridePolicy(
          enabledOverrideTypes: [OverrideType.immediate],
          maxOverridesPerDay: 2,
          usedOverridesToday: 2,
        ),
      );
      final res2 = coord2.validateImmediateOverride();
      expect(res2.isSuccessful, isFalse);
      expect(res2.errorMessage, contains('exhausted'));
    });

    test('validateConfirmationPhrase branch testing', () {
      // 1. Not enabled
      final c1 = OverrideCoordinator(
        policy: const OverridePolicy(enabledOverrideTypes: []),
      );
      expect(
        c1
            .validateConfirmationPhrase(
                candidatePhrase: 'phrase', reason: 'reason')
            .isSuccessful,
        isFalse,
      );

      // 2. Quota exhausted
      final c2 = OverrideCoordinator(
        policy: const OverridePolicy(
          enabledOverrideTypes: [OverrideType.confirmationPhrase],
          maxOverridesPerDay: 1,
          usedOverridesToday: 1,
        ),
      );
      expect(
        c2
            .validateConfirmationPhrase(
                candidatePhrase: 'phrase', reason: 'reason')
            .isSuccessful,
        isFalse,
      );

      // 3. Reason too short
      final c3 = OverrideCoordinator(
        policy: const OverridePolicy(
          enabledOverrideTypes: [OverrideType.confirmationPhrase],
          requireReason: true,
          confirmationPhrase: 'Match me',
        ),
      );
      final res3 = c3.validateConfirmationPhrase(
        candidatePhrase: 'Match me',
        reason: 'no',
      );
      expect(res3.isSuccessful, isFalse);
      expect(res3.errorMessage, contains('at least 5 characters'));

      // 4. Mismatch
      final res4 = c3.validateConfirmationPhrase(
        candidatePhrase: 'Wrong',
        reason: 'Valid long reason',
      );
      expect(res4.isSuccessful, isFalse);
      expect(res4.errorMessage, contains('does not match'));
    });

    test('validatePin all validation branches', () {
      final salt = PinHasher.generateSalt();
      final hash = PinHasher.hashPin('9876', salt);

      // 1. Not required or unconfigured
      final c1 = OverrideCoordinator(
        policy: const OverridePolicy(isPinRequired: false),
      );
      expect(
        c1
            .validatePin(candidatePin: '9876', reason: 'valid reason')
            .isSuccessful,
        isFalse,
      );

      // 2. Quota exhausted
      final c2 = OverrideCoordinator(
        policy: const OverridePolicy(
          isPinRequired: true,
          maxOverridesPerDay: 1,
          usedOverridesToday: 1,
        ),
        storedPinHash: hash,
        storedPinSalt: salt,
      );
      expect(
        c2
            .validatePin(candidatePin: '9876', reason: 'valid reason')
            .isSuccessful,
        isFalse,
      );

      // 3. Reason too short
      final c3 = OverrideCoordinator(
        policy: const OverridePolicy(
          isPinRequired: true,
          requireReason: true,
          maxOverridesPerDay: 5,
        ),
        storedPinHash: hash,
        storedPinSalt: salt,
      );
      expect(
        c3.validatePin(candidatePin: '9876', reason: 'bad').isSuccessful,
        isFalse,
      );

      // 4. Incorrect PIN
      final res4 = c3.validatePin(candidatePin: '0000', reason: 'valid reason');
      expect(res4.isSuccessful, isFalse);
      expect(res4.errorMessage, contains('Incorrect PIN'));

      // 5. Correct PIN
      final res5 = c3.validatePin(candidatePin: '9876', reason: 'valid reason');
      expect(res5.isSuccessful, isTrue);
    });
  });

  group('Domain Models & Repositories Edge Coverage', () {
    test('AppInfo limit calculations and parsing', () {
      const infoWithLimit = AppInfo(
        packageName: 'com.pkg',
        appName: 'Pkg',
        category: AppCategory.entertainment,
        dailyLimitSeconds: 3600,
        usageTodaySeconds: 1800,
      );
      expect(infoWithLimit.hasLimit, isTrue);
      expect(infoWithLimit.isLimitExhausted, isFalse);
      expect(infoWithLimit.limitProgress, closeTo(0.5, 0.01));

      const exhaustedInfo = AppInfo(
        packageName: 'com.pkg',
        appName: 'Pkg',
        category: AppCategory.gaming,
        dailyLimitSeconds: 1000,
        usageTodaySeconds: 1200,
      );
      expect(exhaustedInfo.isLimitExhausted, isTrue);
      expect(exhaustedInfo.limitProgress, equals(1.0));

      // AppInfo fromMap fallback
      final parsed = AppInfo.fromMap({
        'packageName': 'com.test',
        'appName': 'Test',
        'category': 'unknown_category',
      });
      expect(parsed.category, equals(AppCategory.utility));
    });

    test('OverridePolicy remaining calculation and parsing', () {
      const policy = OverridePolicy(
        maxOverridesPerDay: 5,
        usedOverridesToday: 3,
      );
      expect(policy.remainingOverridesToday, equals(2));

      final emptyTypes = OverridePolicy.fromMap({
        'enabledOverrideTypes': '',
      });
      expect(emptyTypes.enabledOverrideTypes, contains(OverrideType.emergency));
    });

    test('Database Repositories update, delete, getById', () async {
      final db = DatabaseHelper.instance;
      final sessionRepo = SessionRepository(databaseHelper: db);
      final scheduleRepo = ScheduleRepository(databaseHelper: db);
      final profileRepo = ProfileRepository(databaseHelper: db);
      final auditRepo = AuditRepository(databaseHelper: db);

      // SessionRepository
      const session = FocusSession(
        id: 'session_test_repo',
        profileId: 'profile_1',
        profileName: 'Study',
        restrictionStrength: RestrictionStrength.strict,
        totalDurationSeconds: 600,
        monotonicStartMs: 1000,
        monotonicTargetMs: 601000,
        wallClockStartMs: 1000,
        wallClockTargetMs: 601000,
        state: SessionState.active,
        bootCountAtStart: 1,
      );
      await sessionRepo.saveSession(session);
      final retrieved = await sessionRepo.getSessionById('session_test_repo');
      expect(retrieved?.id, equals('session_test_repo'));

      final updatedSession = session.copyWith(breaksTaken: 1);
      await sessionRepo.updateSession(updatedSession);
      final allSessions = await sessionRepo.getAllSessions();
      expect(allSessions.any((s) => s.id == 'session_test_repo'), isTrue);

      // ScheduleRepository
      const sched = FocusSchedule(
        id: 'sched_test_repo',
        name: 'Morning Focus',
        profileId: 'profile_1',
        startHour: 9,
        startMinute: 0,
        endHour: 10,
        endMinute: 0,
        daysOfWeek: [1, 2, 3],
        isEnabled: true,
      );
      await scheduleRepo.saveSchedule(sched);
      await scheduleRepo.updateSchedule(sched.copyWith(name: 'Updated Focus'));
      var allScheds = await scheduleRepo.getAllSchedules();
      expect(allScheds.firstWhere((s) => s.id == 'sched_test_repo').name,
          equals('Updated Focus'));
      await scheduleRepo.deleteSchedule('sched_test_repo');
      allScheds = await scheduleRepo.getAllSchedules();
      expect(allScheds.any((s) => s.id == 'sched_test_repo'), isFalse);

      // ProfileRepository
      const customProf = FocusProfile(
        id: 'prof_custom_repo',
        name: 'Custom Profile',
        description: 'Test profile description',
        iconName: 'tune',
        restrictionStrength: RestrictionStrength.strict,
        blockedPackageNames: ['com.bad.app'],
        allowedPackageNames: ['com.good.app'],
        isDefault: false,
      );
      await profileRepo.saveProfile(customProf);
      await profileRepo.updateProfile(customProf.copyWith(name: 'Renamed'));
      var allProfs = await profileRepo.getAllProfiles();
      expect(allProfs.firstWhere((p) => p.id == 'prof_custom_repo').name,
          equals('Renamed'));
      await profileRepo.deleteProfile('prof_custom_repo');

      final def = await profileRepo.getDefaultProfile();
      expect(def, isNotNull);

      // AuditRepository
      final logs = await auditRepo.getAllLogs();
      expect(logs, isA<List<AuditEntry>>());
    });
  });
}
