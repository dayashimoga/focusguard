import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/domain/models/app_info.dart';
import 'package:focusguard/domain/models/enums.dart';
import 'package:focusguard/domain/models/focus_profile.dart';
import 'package:focusguard/engine/focus_engine.dart';
import 'package:focusguard/persistence/database_helper.dart';
import 'package:focusguard/persistence/profile_repository.dart';
import 'package:focusguard/platform/platform_bridge.dart';
import 'package:focusguard/presentation/screens/app_selection_screen.dart';
import 'package:focusguard/presentation/screens/help_emergency_screen.dart';
import 'package:focusguard/presentation/screens/home_screen.dart';
import 'package:focusguard/presentation/screens/permissions_screen.dart';
import 'package:focusguard/presentation/screens/profiles_screen.dart';
import 'package:focusguard/presentation/screens/start_focus_screen.dart';

class StubPlatformBridge implements PlatformBridge {
  @override
  Future<Map<String, dynamic>> getCapabilities() async => {
        'platform': 'android',
        'osVersion': 34,
        'hasUsageStatsPermission': true,
        'hasOverlayPermission': true,
        'hasAccessibilityPermission': false,
        'hasDndPermission': true,
        'hasMonotonicClock': true,
        'isDeviceOwner': false,
      };

  @override
  Future<int> getMonotonicElapsedRealtime() async => 10000;

  @override
  Future<int> getBootCount() async => 0;

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
  late StubPlatformBridge bridge;
  late FocusEngine engine;

  setUp(() {
    bridge = StubPlatformBridge();
    engine = FocusEngine(platformBridge: bridge);
  });

  tearDown(() {
    engine.dispose();
  });

  group('Widget: Screen Render Tests', () {
    testWidgets('renders HomeScreen with quick presets and wellbeing cards',
        (tester) async {
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

      expect(find.text('FocusGuard'), findsOneWidget);
      expect(find.text('Quick Focus'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('60'), findsOneWidget);
      expect(find.text("Today's Wellbeing"), findsOneWidget);
    });

    testWidgets('renders StartFocusScreen with duration slider and presets',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StartFocusScreen(
            focusEngine: engine,
            profiles: FocusProfile.defaultPresets,
          ),
        ),
      );

      expect(find.text('Start Focus Session'), findsOneWidget);
      expect(find.text('Session Duration'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Deep Work'), findsOneWidget);
      expect(find.text('Until 7:00 AM'), findsOneWidget);
    });

    testWidgets('renders AppSelectionScreen with search, categories, and apps',
        (tester) async {
      const apps = [
        AppInfo(
          packageName: 'com.instagram.android',
          appName: 'Instagram',
          category: AppCategory.social,
        ),
        AppInfo(
          packageName: 'com.android.dialer',
          appName: 'Phone Dialer',
          category: AppCategory.communication,
          isEssential: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: AppSelectionScreen(
            installedApps: apps,
            initialBlockedPackages: {'com.instagram.android'},
            onSaveBlockedPackages: (_) {},
          ),
        ),
      );

      expect(find.text('Select Blocked Apps'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('Phone Dialer'), findsOneWidget);
      expect(find.text('ESSENTIAL'), findsOneWidget);
      expect(find.text('1 Apps Selected to Block'), findsOneWidget);
    });

    testWidgets('renders ProfilesScreen with preset cards', (tester) async {
      final repo = ProfileRepository(databaseHelper: DatabaseHelper.instance);
      await repo.initProfiles();

      await tester.pumpWidget(
        MaterialApp(
          home: ProfilesScreen(profileRepository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Focus Profiles'), findsOneWidget);
      expect(find.text('Deep Work'), findsOneWidget);
      expect(find.text('Study & Learning'), findsOneWidget);
    });

    testWidgets(
        'renders PermissionsScreen with diagnostics and capability matrix',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: PermissionsScreen(platformBridge: bridge),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Permissions & Diagnostics'), findsOneWidget);
      expect(find.text('Enforcement Health'), findsOneWidget);
      expect(find.text('Platform Capability Matrix'), findsOneWidget);
      expect(find.text('Foreground App Detection'), findsOneWidget);
    });

    testWidgets('renders HelpEmergencyScreen with emergency dialer access CTA',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HelpEmergencyScreen(focusEngine: engine),
        ),
      );

      expect(find.text('Emergency & Safety'), findsOneWidget);
      expect(find.text('Emergency Dialer Access'), findsOneWidget);
      expect(find.text('Open Emergency Dialer & Unlock'), findsOneWidget);
      expect(find.text('Anti-Lockout Invariant'), findsOneWidget);
    });
  });
}
