import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/core/security/pin_hasher.dart';
import 'package:focusguard/domain/models/app_info.dart';
import 'package:focusguard/domain/models/enums.dart';
import 'package:focusguard/domain/models/focus_profile.dart';
import 'package:focusguard/domain/models/focus_schedule.dart';
import 'package:focusguard/domain/models/override_policy.dart';
import 'package:focusguard/engine/focus_engine.dart';
import 'package:focusguard/engine/override_coordinator.dart';
import 'package:focusguard/engine/scheduler.dart';
import 'package:focusguard/persistence/database_helper.dart';
import 'package:focusguard/platform/platform_bridge.dart';

class FullMockBridge extends Fake implements PlatformBridge {
  bool enforcementStarted = false;
  bool enforcementStopped = false;
  List<String> lastBlocked = [];
  List<String> lastAllowed = [];
  String lastLevel = '';

  @override
  Future<Map<String, dynamic>> getCapabilities() async => {
        'platform': 'Android 14',
        'hasUsageStats': true,
        'hasOverlay': true,
        'hasMonotonicClock': true,
      };

  @override
  Future<int> getMonotonicElapsedRealtime() async => 200000;

  @override
  Future<int> getBootCount() async => 2;

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
    lastBlocked = blockedPackages;
    lastAllowed = allowedPackages;
    lastLevel = restrictionLevel;
    return true;
  }

  @override
  Future<bool> stopEnforcement() async {
    enforcementStopped = true;
    enforcementStarted = false;
    return true;
  }

  @override
  Future<List<AppInfo>> getInstalledApps() async => [
        const AppInfo(
          packageName: 'com.instagram.android',
          appName: 'Instagram',
          category: AppCategory.social,
        ),
        const AppInfo(
          packageName: 'com.android.dialer',
          appName: 'Phone',
          category: AppCategory.communication,
          isEssential: true,
        ),
      ];

  @override
  Future<int> getAppDailyUsage(String packageName) async => 350;

  @override
  Future<bool> requestUsageStatsPermission() async => true;

  @override
  Future<bool> requestOverlayPermission() async => true;

  Future<bool> requestAccessibilityPermission() async => true;

  Future<bool> requestNotificationPermission() async => true;

  Future<bool> checkPlatformPermission(String permissionType) async => true;
}

void main() {
  late FullMockBridge bridge;
  late FocusEngine engine;
  int currentMonotonic = 1000000;

  setUp(() {
    bridge = FullMockBridge();
    currentMonotonic = 1000000;
    engine = FocusEngine(
      platformBridge: bridge,
      monotonicTimeProvider: () => currentMonotonic,
    );
  });

  tearDown(() {
    engine.dispose();
  });

  group('Engine: Advanced Lifecycle & Verification', () {
    test(
        'startSession applies exact blocked and allowed packages to native bridge',
        () async {
      const profile = FocusProfile(
        id: 'p_custom_rules',
        name: 'Strict Study',
        description: 'Rules test',
        iconName: 'book',
        restrictionStrength: RestrictionStrength.strict,
        blockedPackageNames: ['com.instagram.android'],
        allowedPackageNames: ['com.android.dialer'],
      );

      await engine.startSession(
        profile: profile,
        durationMinutes: 30,
        gracePeriodSeconds: 0,
      );

      expect(engine.currentState, equals(SessionState.active));
      expect(bridge.enforcementStarted, isTrue);
      expect(bridge.lastBlocked, contains('com.instagram.android'));
      expect(bridge.lastAllowed, contains('com.android.dialer'));
      expect(bridge.lastLevel, equals(RestrictionStrength.strict.name));
    });

    test('break lifecycle with quota enforcement', () async {
      final profile = FocusProfile.defaultPresets.first;
      await engine.startSession(
        profile: profile,
        durationMinutes: 60,
        gracePeriodSeconds: 0,
      );

      // 1. Take break 1 (5 minutes)
      await engine.startBreak(5);
      expect(engine.currentState, equals(SessionState.onBreak));
      expect(bridge.enforcementStopped, isTrue);
      expect(engine.currentSession!.breaksTaken, equals(1));

      // 2. Resume from break
      await engine.resumeFromBreak();
      expect(engine.currentState, equals(SessionState.active));
      expect(bridge.enforcementStarted, isTrue);

      // 3. Take break 2
      await engine.startBreak(10);
      expect(engine.currentSession!.breaksTaken, equals(2));
      await engine.resumeFromBreak();

      // 4. Exceed break quota (max is 2)
      expect(() => engine.startBreak(5), throwsStateError);
      expect(engine.currentState, equals(SessionState.active));
    });

    test('override coordinator phrase and PIN verification flows', () {
      const pin = '1234';
      final salt = PinHasher.generateSalt();
      final hash = PinHasher.hashPin(pin, salt);

      final coordinator = OverrideCoordinator(
        policy: const OverridePolicy(
          enabledOverrideTypes: [
            OverrideType.immediate,
            OverrideType.confirmationPhrase,
            OverrideType.pinProtected,
          ],
          cooldownSeconds: 0,
          confirmationPhrase: 'Unlock now',
          isPinRequired: true,
          requireReason: true,
          maxOverridesPerDay: 3,
        ),
        storedPinSalt: salt,
        storedPinHash: hash,
      );

      // 1. Validate immediate with valid quota
      final r1 = coordinator.validateImmediateOverride();
      expect(r1.isSuccessful, isTrue);

      // 2. Rejects invalid confirmation phrase
      final r2 = coordinator.validateConfirmationPhrase(
        candidatePhrase: 'Wrong phrase',
        reason: 'Valid reason',
      );
      expect(r2.isSuccessful, isFalse);
      expect(r2.errorMessage, contains('match'));

      // 3. Rejects invalid PIN
      final r3 = coordinator.validatePin(
        candidatePin: '9999',
        reason: 'Valid reason',
      );
      expect(r3.isSuccessful, isFalse);
      expect(r3.errorMessage, contains('PIN'));

      // 4. Accepts valid PIN and reason
      final r4 = coordinator.validatePin(
        candidatePin: '1234',
        reason: 'Legitimate need to check work email',
      );
      expect(r4.isSuccessful, isTrue);
    });

    test(
        'scheduler operations: add, remove, setSchedules, and findActiveSchedule',
        () {
      final scheduler = FocusScheduler();

      const sched1 = FocusSchedule(
        id: 's_morning',
        profileId: 'preset_deep_work',
        name: 'Morning Routine',
        startHour: 8,
        startMinute: 0,
        endHour: 10,
        endMinute: 0,
        daysOfWeek: [1, 2, 3, 4, 5],
      );

      const sched2 = FocusSchedule(
        id: 's_evening',
        profileId: 'preset_bedtime',
        name: 'Evening Winddown',
        startHour: 21,
        startMinute: 30,
        endHour: 23,
        endMinute: 0,
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      );

      scheduler.setSchedules([sched1, sched2]);
      expect(scheduler.schedules.length, equals(2));

      // Active schedule lookup
      final testTime = DateTime(2026, 9, 16, 8, 30); // Wednesday 8:30 AM
      final active = scheduler.findActiveSchedule(testTime);
      expect(active, isNotNull);
      expect(active!.id, equals('s_morning'));

      // Next upcoming schedule
      final upcoming =
          scheduler.getNextUpcomingSchedule(DateTime(2026, 9, 16, 7, 0));
      expect(upcoming, isNotNull);
      expect(upcoming!.schedule.id, equals('s_morning'));

      // Remove schedule
      scheduler.removeSchedule('s_morning');
      expect(scheduler.schedules.length, equals(1));
      expect(scheduler.schedules.first.id, equals('s_evening'));
    });

    test('database persistence helper operations', () async {
      final db = DatabaseHelper.instance;
      await db.initDatabase();

      final sessMap = {
        'id': 'test_db_sess_2',
        'profileId': 'preset_deep_work',
        'profileName': 'Deep Work',
        'restrictionStrength': 'deepFocus',
        'totalDurationSeconds': 1800,
        'monotonicStartMs': 1000,
        'monotonicTargetMs': 1801000,
        'wallClockStartMs': 1700000000000,
        'wallClockTargetMs': 1700001800000,
        'state': 'active',
        'breaksTaken': 0,
        'maxBreaksAllowed': 2,
        'distractionAttempts': 0,
        'bootCountAtStart': 1,
      };

      await db.insertSession(sessMap);
      final retrieved = await db.getSession('test_db_sess_2');
      expect(retrieved, isNotNull);
      expect(retrieved!['profileName'], equals('Deep Work'));

      // Query active session
      final active = await db.getActiveSession();
      expect(active, isNotNull);

      // Update session
      sessMap['state'] = 'completed';
      await db.updateSession(sessMap);
      final updated = await db.getSession('test_db_sess_2');
      expect(updated!['state'], equals('completed'));

      // All sessions
      final all = await db.getAllSessions();
      expect(all, isNotEmpty);

      // Settings get/set
      await db.setSetting('test_key_2', 'test_val_2');
      final val = await db.getSetting('test_key_2');
      expect(val, equals('test_val_2'));

      final nonExistent = await db.getSetting('non_existent_key_99');
      expect(nonExistent, isNull);
    });
  });
}
