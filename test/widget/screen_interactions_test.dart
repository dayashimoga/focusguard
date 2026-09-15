import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/domain/models/app_info.dart';
import 'package:focusguard/domain/models/enums.dart';
import 'package:focusguard/domain/models/focus_profile.dart';
import 'package:focusguard/engine/focus_engine.dart';
import 'package:focusguard/platform/platform_bridge.dart';
import 'package:focusguard/presentation/screens/app_selection_screen.dart';
import 'package:focusguard/presentation/screens/home_screen.dart';
import 'package:focusguard/presentation/screens/start_focus_screen.dart';

class InteractionMockBridge extends Fake implements PlatformBridge {
  bool enforcementStarted = false;

  @override
  Future<Map<String, dynamic>> getCapabilities() async => {'platform': 'mock'};

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
    enforcementStarted = true;
    return true;
  }

  @override
  Future<bool> stopEnforcement() async => true;

  @override
  Future<List<AppInfo>> getInstalledApps() async => [];
}

void main() {
  late InteractionMockBridge bridge;
  late FocusEngine engine;

  setUp(() {
    bridge = InteractionMockBridge();
    engine = FocusEngine(
      platformBridge: bridge,
      monotonicTimeProvider: () => 100000,
    );
  });

  tearDown(() {
    engine.dispose();
  });

  group('Widget: Interactive UI Operations', () {
    testWidgets('StartFocusScreen slider and preset selection', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: StartFocusScreen(
            focusEngine: engine,
            profiles: FocusProfile.defaultPresets,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap preset 'Study & Learning'
      final studyPresetFinder = find.text('Study & Learning');
      expect(studyPresetFinder, findsOneWidget);
      await tester.tap(studyPresetFinder);
      await tester.pumpAndSettle();

      // Drag Slider
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);
      await tester.drag(sliderFinder, const Offset(100, 0));
      await tester.pumpAndSettle();

      // Tap Start Focus button
      final startBtn = find.byType(ElevatedButton).first;
      expect(startBtn, findsOneWidget);
      await tester.tap(startBtn);
      await tester.pump();

      expect(engine.hasActiveSession, isTrue);
      await engine.emergencyExit();
    });

    testWidgets('AppSelectionScreen search and category filters',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const apps = [
        AppInfo(
          packageName: 'com.instagram.android',
          appName: 'Instagram',
          category: AppCategory.social,
        ),
        AppInfo(
          packageName: 'com.netflix.mediaclient',
          appName: 'Netflix',
          category: AppCategory.entertainment,
        ),
        AppInfo(
          packageName: 'com.android.dialer',
          appName: 'Phone',
          category: AppCategory.communication,
          isEssential: true,
        ),
      ];

      Set<String>? savedBlocked;

      await tester.pumpWidget(
        MaterialApp(
          home: AppSelectionScreen(
            installedApps: apps,
            initialBlockedPackages: const {'com.instagram.android'},
            onSaveBlockedPackages: (selected) {
              savedBlocked = selected;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search field: enter query
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Netflix');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Netflix'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Instagram'), findsNothing);

      // Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Instagram'), findsOneWidget);

      // Tap Netflix to toggle selection
      await tester.tap(find.widgetWithText(ListTile, 'Netflix'));
      await tester.pumpAndSettle();

      // Tap Save check button in AppBar
      final saveBtn = find.byIcon(Icons.check);
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(savedBlocked, isNotNull);
      expect(savedBlocked!.contains('com.netflix.mediaclient'), isTrue);
    });

    testWidgets('HomeScreen quick focus action triggers session',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            focusEngine: engine,
            onNavigateToStart: () {},
            onNavigateToProfiles: () {},
            onNavigateToSchedules: () {},
            onNavigateToEmergency: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick Focus'), findsOneWidget);
      expect(find.text('Custom Duration →'), findsOneWidget);

      // Tap quick 15m preset
      final quick15 = find.text('15');
      expect(quick15, findsOneWidget);
      await tester.tap(quick15);
      await tester.pump();

      expect(engine.hasActiveSession, isTrue);
      await engine.emergencyExit();
    });
  });
}
