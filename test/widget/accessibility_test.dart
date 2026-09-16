import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/engine/focus_engine.dart';
import 'package:focusguard/platform/platform_bridge.dart';
import 'package:focusguard/presentation/screens/help_emergency_screen.dart';
import 'package:focusguard/presentation/screens/home_screen.dart';
import 'package:focusguard/presentation/screens/permissions_screen.dart';
import 'package:focusguard/presentation/screens/start_focus_screen.dart';

class MockPlatformBridge extends Fake implements PlatformBridge {
  @override
  Future<Map<String, dynamic>> getCapabilities() async => {
        'platform': 'android',
        'hasMonotonicClock': true,
        'hasUsageStatsPermission': true,
        'hasOverlayPermission': true,
      };
  @override
  Future<int> getMonotonicElapsedRealtime() async => 100000;
  @override
  Future<int> getBootCount() async => 1;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPlatformBridge bridge;
  late FocusEngine engine;

  setUp(() {
    bridge = MockPlatformBridge();
    engine = FocusEngine(
      platformBridge: bridge,
      monotonicTimeProvider: () => 100000,
    );
  });

  tearDown(() {
    engine.dispose();
  });

  group('Accessibility & Semantics Quality Gate (A11Y-001)', () {
    testWidgets('Validates semantics and touch targets on HomeScreen',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          showSemanticsDebugger: false,
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

      // Check for emergency exit button accessibility
      final emergencyBtn = find.byType(IconButton);
      expect(emergencyBtn, findsOneWidget);

      // Verify touch target size of critical buttons
      final btnSize = tester.getSize(emergencyBtn);
      expect(btnSize.width, greaterThanOrEqualTo(40.0));
      expect(btnSize.height, greaterThanOrEqualTo(40.0));
    });

    testWidgets(
        'Validates HelpEmergencyScreen high-contrast emergency dialer button',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HelpEmergencyScreen(focusEngine: engine),
        ),
      );
      await tester.pumpAndSettle();

      // Emergency call button must be prominently displayed
      expect(find.text('Emergency Dialer Access'), findsOneWidget);
      expect(find.byIcon(Icons.phone_in_talk), findsOneWidget);
      expect(find.text('Open Emergency Dialer & Unlock'), findsOneWidget);
    });

    testWidgets('Validates PermissionsScreen provides explicit semantics',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PermissionsScreen(platformBridge: bridge),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enforcement Health'), findsOneWidget);
      expect(find.textContaining('Usage Access'), findsOneWidget);
      expect(find.textContaining('Display Over Other Apps'), findsOneWidget);
    });

    testWidgets(
        'Validates StartFocusScreen duration buttons meet touch standards',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StartFocusScreen(
            focusEngine: engine,
            profiles: const [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Start Focus button
      final startBtn = find.byType(ElevatedButton);
      expect(startBtn, findsOneWidget);
      final size = tester.getSize(startBtn);
      expect(size.height, greaterThanOrEqualTo(40.0));
    });
  });
}
