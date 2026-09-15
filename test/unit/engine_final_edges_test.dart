import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/domain/models/app_info.dart';
import 'package:focusguard/domain/models/enums.dart';
import 'package:focusguard/domain/models/focus_profile.dart';
import 'package:focusguard/engine/focus_engine.dart';
import 'package:focusguard/persistence/database_helper.dart';
import 'package:focusguard/persistence/settings_repository.dart';
import 'package:focusguard/platform/platform_bridge.dart';
import 'package:focusguard/presentation/screens/active_session_screen.dart';
import 'package:focusguard/presentation/screens/override_config_screen.dart';

class EdgeMockBridge extends Fake implements PlatformBridge {
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
  }) async =>
      true;
  @override
  Future<bool> stopEnforcement() async => true;
  @override
  Future<List<AppInfo>> getInstalledApps() async => [];
}

void main() {
  late EdgeMockBridge bridge;
  late FocusEngine engine;
  late SettingsRepository settingsRepo;

  setUp(() {
    bridge = EdgeMockBridge();
    engine = FocusEngine(
      platformBridge: bridge,
      monotonicTimeProvider: () => 100000,
    );
    settingsRepo = SettingsRepository(databaseHelper: DatabaseHelper.instance);
  });

  tearDown(() {
    engine.dispose();
  });

  group('Engine & Screen: Final Edge Branches', () {
    test('FocusEngine overrideSession with typedReason', () async {
      await engine.startSession(
        profile: FocusProfile.defaultPresets.first,
        durationMinutes: 30,
        gracePeriodSeconds: 0,
      );

      // Short reason fails
      expect(
        () => engine.overrideSession(
            type: OverrideType.typedReason, typedReason: 'abc'),
        throwsStateError,
      );

      // Valid reason succeeds
      await engine.overrideSession(
        type: OverrideType.typedReason,
        typedReason: 'Need to make urgent business call',
      );
      expect(engine.currentState, equals(SessionState.overridden));
    });

    test('FocusEngine overrideSession with delayedCooldown', () async {
      await engine.startSession(
        profile: FocusProfile.defaultPresets.first,
        durationMinutes: 30,
        gracePeriodSeconds: 0,
      );

      await engine.overrideSession(
        type: OverrideType.delayedCooldown,
        typedReason: 'Delayed exit test',
      );
      expect(engine.currentState, equals(SessionState.overridden));
    });

    testWidgets('ActiveSessionScreen emergency exit dialog confirmation flow',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await engine.startSession(
        profile: FocusProfile.defaultPresets.first,
        durationMinutes: 45,
        gracePeriodSeconds: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ActiveSessionScreen(focusEngine: engine),
        ),
      );
      await tester.pumpAndSettle();

      // Tap emergency icon in AppBar
      final sosBtn = find.byIcon(Icons.emergency_outlined);
      expect(sosBtn, findsOneWidget);
      await tester.tap(sosBtn);
      await tester.pumpAndSettle();

      expect(find.text('Emergency Exit'), findsOneWidget);

      // Tap Immediate Emergency Exit button
      final exitConfirm = find.text('Immediate Emergency Exit');
      expect(exitConfirm, findsOneWidget);
      await tester.tap(exitConfirm);
      await tester.pumpAndSettle();

      expect(engine.currentState, equals(SessionState.overridden));
    });

    testWidgets('OverrideConfigScreen set PIN dialog flow', (tester) async {
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

      // Tap Set PIN button
      final setPinBtn = find.widgetWithText(ElevatedButton, 'Set PIN');
      expect(setPinBtn, findsOneWidget);
      await tester.tap(setPinBtn);
      await tester.pumpAndSettle();

      expect(find.text('Set 4-8 Digit PIN'), findsOneWidget);
      final pinField = find.byType(TextField);
      expect(pinField, findsOneWidget);
      await tester.enterText(pinField, '1234');
      await tester.pumpAndSettle();

      final savePinBtn = find.widgetWithText(ElevatedButton, 'Save PIN');
      expect(savePinBtn, findsOneWidget);
      await tester.tap(savePinBtn);
      await tester.pumpAndSettle();

      expect(find.text('PIN Protection Active'), findsOneWidget);
    });
  });
}
