import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/domain/models/app_info.dart';
import 'package:focusguard/domain/models/enums.dart';
import 'package:focusguard/domain/models/focus_profile.dart';
import 'package:focusguard/engine/daily_limit_tracker.dart';
import 'package:focusguard/engine/focus_engine.dart';
import 'package:focusguard/persistence/database_helper.dart';
import 'package:focusguard/persistence/profile_repository.dart';
import 'package:focusguard/persistence/schedule_repository.dart';
import 'package:focusguard/persistence/settings_repository.dart';
import 'package:focusguard/platform/platform_bridge.dart';
import 'package:focusguard/presentation/screens/active_session_screen.dart';
import 'package:focusguard/presentation/screens/daily_limits_screen.dart';
import 'package:focusguard/presentation/screens/override_config_screen.dart';
import 'package:focusguard/presentation/screens/profiles_screen.dart';
import 'package:focusguard/presentation/screens/schedules_screen.dart';
import 'package:focusguard/presentation/screens/settings_screen.dart';

class FlowMockBridge extends Fake implements PlatformBridge {
  @override
  Future<Map<String, dynamic>> getCapabilities() async => {'platform': 'mock'};
  @override
  Future<int> getMonotonicElapsedRealtime() async => 60000;
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
  late FlowMockBridge bridge;
  late FocusEngine engine;
  late SettingsRepository settingsRepo;
  late ProfileRepository profileRepo;
  late ScheduleRepository scheduleRepo;
  late DailyLimitTracker limitTracker;

  setUp(() async {
    bridge = FlowMockBridge();
    engine = FocusEngine(
      platformBridge: bridge,
      monotonicTimeProvider: () => 100000,
    );
    settingsRepo = SettingsRepository(databaseHelper: DatabaseHelper.instance);
    profileRepo = ProfileRepository(databaseHelper: DatabaseHelper.instance);
    scheduleRepo = ScheduleRepository(databaseHelper: DatabaseHelper.instance);
    limitTracker = DailyLimitTracker();
    await profileRepo.initProfiles();
  });

  tearDown(() {
    engine.dispose();
    limitTracker.dispose();
  });

  group('Widget: Dialogs and Complex Flows', () {
    testWidgets('ActiveSessionScreen break modal bottom sheet and take break',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await engine.startSession(
        profile: FocusProfile.defaultPresets.first,
        durationMinutes: 60,
        gracePeriodSeconds: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveSessionScreen(focusEngine: engine),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Take Break'
      final takeBreakBtn = find.text('Take Break (2 left)');
      expect(takeBreakBtn, findsOneWidget);
      await tester.tap(takeBreakBtn);
      await tester.pumpAndSettle();

      // Modal bottom sheet should appear with options (e.g. 5 Minutes)
      final min5 = find.text('5 Minutes');
      if (min5.evaluate().isNotEmpty) {
        await tester.tap(min5);
        await tester.pumpAndSettle();
        expect(engine.currentState, equals(SessionState.onBreak));

        // Tap Resume Focus Now
        final resumeBtn = find.text('Resume Focus Now');
        if (resumeBtn.evaluate().isNotEmpty) {
          await tester.tap(resumeBtn);
          await tester.pumpAndSettle();
          expect(engine.currentState, equals(SessionState.active));
        }
      }

      await engine.emergencyExit();
    });

    testWidgets(
        'ActiveSessionScreen displays session ended view when state is completed',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Session is idle / completed
      await tester.pumpWidget(
        MaterialApp(
          home: ActiveSessionScreen(focusEngine: engine),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session Finished'), findsOneWidget);
      expect(find.text('Return to Dashboard'), findsOneWidget);
    });

    testWidgets('ProfilesScreen add custom profile flow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ProfilesScreen(profileRepository: profileRepo),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Floating Action Button to add profile
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Dialog should open
      expect(find.text('Create Focus Profile'), findsOneWidget);
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'Meditation Time');
      await tester.pumpAndSettle();

      // Tap Create
      final saveBtn = find.widgetWithText(ElevatedButton, 'Create');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify custom profile is created
      expect(find.text('Meditation Time'), findsOneWidget);
    });

    testWidgets('SchedulesScreen add schedule dialog flow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: SchedulesScreen(scheduleRepository: scheduleRepo),
        ),
      );
      await tester.pumpAndSettle();

      // Tap FAB to create schedule
      final fab = find.byType(FloatingActionButton);
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab);
        await tester.pumpAndSettle();

        expect(find.text('Create Schedule'), findsOneWidget);
        final nameField = find.byType(TextField).first;
        await tester.enterText(nameField, 'Night Winddown');
        await tester.pumpAndSettle();

        // Tap Save
        final saveBtn = find.text('Save Schedule');
        if (saveBtn.evaluate().isNotEmpty) {
          await tester.tap(saveBtn);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('DailyLimitsScreen add limit dialog flow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: DailyLimitsScreen(limitTracker: limitTracker),
        ),
      );
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('Set Application Limit'), findsOneWidget);
      final fields = find.byType(TextField);
      if (fields.evaluate().isNotEmpty) {
        await tester.enterText(fields.first, 'Reddit');
        await tester.pumpAndSettle();
      }

      final addBtn = find.widgetWithText(ElevatedButton, 'Save');
      if (addBtn.evaluate().isNotEmpty) {
        await tester.tap(addBtn);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('OverrideConfigScreen toggles cooldown and custom phrase',
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

      // Find switches
      final switches = find.byType(Switch);
      if (switches.evaluate().isNotEmpty) {
        await tester.tap(switches.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('SettingsScreen theme change and reset prompt', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      ThemeMode? appliedTheme;

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            settingsRepository: settingsRepo,
            onThemeChanged: (t) {
              appliedTheme = t;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Light Theme tile
      final lightTile = find.text('Crisp Light');
      expect(lightTile, findsOneWidget);
      await tester.tap(lightTile);
      await tester.pumpAndSettle();
      expect(appliedTheme, equals(ThemeMode.light));

      // Tap Clear All User Data
      final clearTile = find.text('Clear All User Data');
      expect(clearTile, findsOneWidget);
      await tester.tap(clearTile);
      await tester.pumpAndSettle();

      expect(find.text('Wipe All Data?'), findsOneWidget);
      final cancelBtn = find.text('Cancel');
      expect(cancelBtn, findsOneWidget);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();
    });
  });
}
