import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/domain/models/app_info.dart';
import 'package:focusguard/domain/models/audit_entry.dart';
import 'package:focusguard/domain/models/daily_limit.dart';
import 'package:focusguard/domain/models/focus_profile.dart';
import 'package:focusguard/domain/models/focus_schedule.dart';
import 'package:focusguard/engine/daily_limit_tracker.dart';
import 'package:focusguard/engine/focus_engine.dart';
import 'package:focusguard/persistence/audit_repository.dart';
import 'package:focusguard/persistence/database_helper.dart';
import 'package:focusguard/persistence/schedule_repository.dart';
import 'package:focusguard/persistence/settings_repository.dart';
import 'package:focusguard/platform/platform_bridge.dart';
import 'package:focusguard/presentation/screens/active_session_screen.dart';
import 'package:focusguard/presentation/screens/daily_limits_screen.dart';
import 'package:focusguard/presentation/screens/history_screen.dart';
import 'package:focusguard/presentation/screens/override_config_screen.dart';
import 'package:focusguard/presentation/screens/schedules_screen.dart';
import 'package:focusguard/presentation/screens/settings_screen.dart';
import 'package:focusguard/presentation/screens/usage_insights_screen.dart';

class MockPlatformBridge extends Fake implements PlatformBridge {
  bool enforcementActive = false;

  @override
  Future<Map<String, dynamic>> getCapabilities() async =>
      {'platform': 'mock', 'hasMonotonicClock': true};

  @override
  Future<int> getMonotonicElapsedRealtime() async => 50000;

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
    enforcementActive = true;
    return true;
  }

  @override
  Future<bool> stopEnforcement() async {
    enforcementActive = false;
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

  Future<bool> requestAccessibilityPermission() async => true;

  Future<bool> requestNotificationPermission() async => true;

  Future<bool> checkPlatformPermission(String permissionType) async => true;
}

void main() {
  late MockPlatformBridge bridge;
  late FocusEngine engine;
  late SettingsRepository settingsRepo;
  late AuditRepository auditRepo;
  late ScheduleRepository scheduleRepo;
  late DailyLimitTracker limitTracker;

  setUp(() async {
    bridge = MockPlatformBridge();
    engine = FocusEngine(
      platformBridge: bridge,
      monotonicTimeProvider: () => 100000,
    );
    settingsRepo = SettingsRepository(databaseHelper: DatabaseHelper.instance);
    auditRepo = AuditRepository(databaseHelper: DatabaseHelper.instance);
    scheduleRepo = ScheduleRepository(databaseHelper: DatabaseHelper.instance);
    limitTracker = DailyLimitTracker();
  });

  tearDown(() {
    engine.dispose();
    limitTracker.dispose();
  });

  group('Widget: Comprehensive Screen Coverage', () {
    testWidgets('renders ActiveSessionScreen during ongoing active session',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Start a session
      final profile = FocusProfile.defaultPresets.first;
      await engine.startSession(
        profile: profile,
        durationMinutes: 45,
        gracePeriodSeconds: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveSessionScreen(focusEngine: engine),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Deep Work'), findsOneWidget);
      expect(find.text('ENFORCEMENT ACTIVE • DEEPFOCUS'), findsOneWidget);
      expect(find.text('Take Break (2 left)'), findsOneWidget);
      expect(find.text('Exit Focus Session'), findsOneWidget);

      await engine.emergencyExit();
    });

    testWidgets('renders DailyLimitsScreen with limits and add limit card',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      limitTracker.setLimits([
        const DailyLimit(
          id: 'dl_social',
          packageName: 'com.instagram.android',
          appName: 'Instagram',
          limitMinutes: 45,
          usedMinutes: 30,
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: DailyLimitsScreen(limitTracker: limitTracker),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily App Limits'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('15m left'), findsOneWidget);
    });

    testWidgets(
        'renders OverrideConfigScreen with friction controls and phrase',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: OverrideConfigScreen(
            focusEngine: engine,
            settingsRepository: settingsRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Override & Safety Policy'), findsOneWidget);
      expect(find.text('Friction Mechanisms'), findsOneWidget);
      expect(find.text('Delayed Cooldown Timer'), findsOneWidget);
    });

    testWidgets('renders UsageInsightsScreen with privacy callout and metrics',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: UsageInsightsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Usage Insights & Analytics'), findsOneWidget);
      expect(find.text('Total Focus Time'), findsOneWidget);
      expect(find.text('Completion Rate'), findsOneWidget);
      expect(find.text('Most Frequently Deflected Apps'), findsOneWidget);
    });

    testWidgets('renders HistoryScreen with audit entries', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await auditRepo.logEvent(
        const AuditEntry(
          id: 'audit_100',
          timestampMs: 1700000000000,
          eventType: 'session_start',
          description: 'Deep Work session started for 60m',
          sessionId: 'sess_hist_1',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HistoryScreen(auditRepository: auditRepo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session History & Audit Log'), findsOneWidget);
      expect(find.text('SESSION START'), findsOneWidget);
      expect(find.text('Deep Work session started for 60m'), findsOneWidget);
    });

    testWidgets(
        'renders SettingsScreen with theme, backup, and privacy actions',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            settingsRepository: settingsRepo,
            onThemeChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings & Privacy'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Obsidian Dark (Default)'), findsOneWidget);
      expect(find.text('Privacy & Reset'), findsOneWidget);
      expect(find.text('Clear All User Data'), findsOneWidget);
    });

    testWidgets('renders SchedulesScreen with recurring schedules',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const sched = FocusSchedule(
        id: 'sched_morning_routine',
        profileId: 'preset_deep_work',
        name: 'Morning Routine',
        startHour: 7,
        startMinute: 0,
        endHour: 8,
        endMinute: 30,
        daysOfWeek: [1, 2, 3, 4, 5],
      );
      await scheduleRepo.saveSchedule(sched);

      await tester.pumpWidget(
        MaterialApp(
          home: SchedulesScreen(scheduleRepository: scheduleRepo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recurring Schedules'), findsOneWidget);
      expect(find.text('Morning Routine'), findsOneWidget);
      expect(find.text('7:00 AM – 8:30 AM'), findsOneWidget);
    });
  });
}
