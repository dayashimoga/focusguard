import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/domain/models/app_info.dart';
import 'package:focusguard/domain/models/degradation_report.dart';
import 'package:focusguard/domain/models/enums.dart';
import 'package:focusguard/domain/models/focus_profile.dart';
import 'package:focusguard/domain/models/focus_session.dart';
import 'package:focusguard/domain/models/override_policy.dart';
import 'package:focusguard/engine/focus_engine.dart';
import 'package:focusguard/persistence/database_helper.dart';
import 'package:focusguard/persistence/profile_repository.dart';
import 'package:focusguard/platform/platform_bridge.dart';
import 'package:focusguard/presentation/screens/active_session_screen.dart';
import 'package:focusguard/presentation/screens/home_screen.dart';
import 'package:focusguard/presentation/screens/permissions_screen.dart';

class FlowTestBridge extends Fake implements PlatformBridge {
  @override
  Future<Map<String, dynamic>> getCapabilities() async => {
        'platform': 'mock',
        'hasUsageStatsPermission': true,
        'hasOverlayPermission': true,
        'isEnforcementRunning': true,
      };

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

  late FlowTestBridge bridge;
  late FocusEngine engine;
  late ProfileRepository profileRepo;

  setUp(() async {
    bridge = FlowTestBridge();
    engine = FocusEngine(
      platformBridge: bridge,
      monotonicTimeProvider: () => 100000,
      overridePolicy: const OverridePolicy(
        enabledOverrideTypes: [
          OverrideType.confirmationPhrase,
          OverrideType.emergency,
        ],
        confirmationPhrase: 'I confirm focus exit',
        requireReason: true,
      ),
    );
    profileRepo = ProfileRepository(databaseHelper: DatabaseHelper.instance);
    await profileRepo.initProfiles();
  });

  tearDown(() {
    engine.dispose();
  });

  group('Interactive UI Flows & Degradation Coverage', () {
    testWidgets('HomeScreen handles degraded protection banner and navigation',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      engine.setDegradation(
        DegradationReport.degraded(
          missingPermissions: ['PACKAGE_USAGE_STATS'],
          affectedMechanisms: ['Foreground tracking disabled'],
          remediationInstructions: ['Open Settings and enable usage access'],
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      bool startCalled = false;
      bool emergencyCalled = false;
      bool profilesCalled = false;
      bool schedulesCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            focusEngine: engine,
            onNavigateToStart: () => startCalled = true,
            onNavigateToEmergency: () => emergencyCalled = true,
            onNavigateToProfiles: () => profilesCalled = true,
            onNavigateToSchedules: () => schedulesCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PROTECTION DEGRADED'), findsOneWidget);
      expect(find.text('Restore Protection Now'), findsOneWidget);

      // Tap 'Restore Protection Now' -> navigates to PermissionsScreen
      await tester.tap(find.text('Restore Protection Now'));
      await tester.pumpAndSettle();
      expect(find.byType(PermissionsScreen), findsOneWidget);

      // Pop back to HomeScreen
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Tap navigation buttons
      await tester.tap(find.text('Profiles'));
      expect(profilesCalled, isTrue);
      await tester.tap(find.text('Schedules'));
      expect(schedulesCalled, isTrue);

      // Tap Custom Duration button
      await tester.tap(find.text('Custom Duration →'));
      expect(startCalled, isTrue);

      // Tap Emergency icon
      await tester.tap(find.byIcon(Icons.sos));
      expect(emergencyCalled, isTrue);

      // Tap quick start duration card (15 min)
      final min15 = find.text('15');
      expect(min15, findsOneWidget);
      await tester.tap(min15);
      await tester.pumpAndSettle();
      expect(engine.hasActiveSession, isTrue);

      // Stop timer cleanly
      await engine.emergencyExit();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'ActiveSessionScreen grace period cancellation and break resumption',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Start session with grace period
      await engine.startSession(
        profile: FocusProfile.defaultPresets.first,
        durationMinutes: 25,
        gracePeriodSeconds: 30,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveSessionScreen(focusEngine: engine),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cancel During Grace Period'), findsOneWidget);
      await tester.tap(find.text('Cancel During Grace Period'));
      await tester.pumpAndSettle();
      expect(engine.currentState, equals(SessionState.idle));
      expect(engine.currentSession, isNull);

      // Now start active session, enter break, and resume via UI
      await engine.startSession(
        profile: FocusProfile.defaultPresets.first,
        durationMinutes: 25,
        gracePeriodSeconds: 0,
      );
      await engine.startBreak(5);
      await tester.pumpAndSettle();

      expect(find.text('Resume Focus Now'), findsOneWidget);
      await tester.tap(find.text('Resume Focus Now'));
      await tester.pumpAndSettle();
      expect(engine.currentState, equals(SessionState.active));

      // Stop timer cleanly
      await engine.emergencyExit();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'ActiveSessionScreen degraded banner and emergency exit confirmation',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await engine.startSession(
        profile: FocusProfile.defaultPresets.first,
        durationMinutes: 25,
        gracePeriodSeconds: 0,
      );

      engine.setDegradation(
        DegradationReport.degraded(
          missingPermissions: ['SYSTEM_ALERT_WINDOW'],
          affectedMechanisms: ['Overlay disabled'],
          remediationInstructions: ['Enable display over other apps'],
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveSessionScreen(focusEngine: engine),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Restore Enforcement Permissions'), findsOneWidget);
      await tester.tap(find.text('Restore Enforcement Permissions'));
      await tester.pumpAndSettle();
      expect(find.byType(PermissionsScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Tap Exit Focus Session
      final exitBtn = find.text('Exit Focus Session');
      expect(exitBtn, findsOneWidget);
      await tester.tap(exitBtn);
      await tester.pumpAndSettle();

      // Override dialog should be shown
      expect(find.text('Exit Focus Session'), findsWidgets);
      expect(find.text('Keep Focusing'), findsOneWidget);
      await tester.tap(find.text('Keep Focusing'));
      await tester.pumpAndSettle();

      // Stop timer cleanly
      await engine.emergencyExit();
      await tester.pumpAndSettle();
    });

    testWidgets('ActiveSessionScreen session ended completed view',
        (tester) async {
      const finishedSession = FocusSession(
        id: 'completed_123',
        profileId: 'default',
        profileName: 'Deep Work',
        restrictionStrength: RestrictionStrength.strict,
        totalDurationSeconds: 1500,
        monotonicStartMs: 1000,
        monotonicTargetMs: 1501000,
        wallClockStartMs: 1000,
        wallClockTargetMs: 1501000,
        state: SessionState.completed,
        bootCountAtStart: 1,
      );
      engine.restoreSession(finishedSession);

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveSessionScreen(focusEngine: engine),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Goal Accomplished!'), findsOneWidget);
      expect(find.text('Return to Dashboard'), findsOneWidget);
      await tester.tap(find.text('Return to Dashboard'));
      await tester.pumpAndSettle();
    });
  });
}
