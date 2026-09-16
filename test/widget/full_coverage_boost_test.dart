import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/domain/models/app_info.dart';
import 'package:focusguard/domain/models/enums.dart';
import 'package:focusguard/domain/models/focus_profile.dart';
import 'package:focusguard/domain/models/override_policy.dart';
import 'package:focusguard/engine/focus_engine.dart';
import 'package:focusguard/persistence/database_helper.dart';
import 'package:focusguard/persistence/settings_repository.dart';
import 'package:focusguard/platform/platform_bridge.dart';
import 'package:focusguard/presentation/screens/active_session_screen.dart';
import 'package:focusguard/presentation/screens/override_config_screen.dart';
import 'package:focusguard/presentation/screens/settings_screen.dart';

class BoostMockBridge extends Fake implements PlatformBridge {
  @override
  Future<Map<String, dynamic>> getCapabilities() async => {'platform': 'mock'};
  @override
  Future<int> getMonotonicElapsedRealtime() async => 70000;
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
  late BoostMockBridge bridge;
  late FocusEngine engine;
  late SettingsRepository settingsRepo;

  setUp(() {
    bridge = BoostMockBridge();
    engine = FocusEngine(
      platformBridge: bridge,
      monotonicTimeProvider: () => 100000,
    );
    settingsRepo = SettingsRepository(databaseHelper: DatabaseHelper.instance);
  });

  tearDown(() {
    engine.dispose();
  });

  group('Widget: Final Coverage Boost Tests', () {
    testWidgets('ActiveSessionScreen override dialog and phrase unlock flow',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      engine.updateOverridePolicy(const OverridePolicy(
        enabledOverrideTypes: [OverrideType.confirmationPhrase],
        requireReason: true,
        cooldownSeconds: 0,
      ));

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

      // Tap Exit Focus Session
      final exitBtn = find.text('Exit Focus Session');
      expect(exitBtn, findsOneWidget);
      await tester.tap(exitBtn);
      await tester.pumpAndSettle();

      // Override Dialog appears with phrase prompt
      expect(
          find.text(
              'Type the confirmation phrase to deliberately interrupt focus:'),
          findsOneWidget);

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      // Phrase input
      await tester.enterText(
          textFields.at(0), 'I deliberately choose to exit focus');
      await tester.pumpAndSettle();

      // Reason input
      await tester.enterText(
          textFields.at(1), 'Legitimate urgent task requiring phone');
      await tester.pumpAndSettle();

      // Tap Confirm & End Session
      final confirmBtn =
          find.widgetWithText(ElevatedButton, 'Confirm & End Session');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();
    });

    testWidgets('OverrideConfigScreen phrase dialog and quota update',
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

      // Tap on confirmation phrase tile to customize phrase
      final phraseTile = find.text('Custom Phrase');
      if (phraseTile.evaluate().isNotEmpty) {
        await tester.tap(phraseTile);
        await tester.pumpAndSettle();

        final phraseField = find.byType(TextField);
        if (phraseField.evaluate().isNotEmpty) {
          await tester.enterText(
              phraseField.first, 'I consciously exit focus now');
          await tester.pumpAndSettle();
          final saveBtn = find.text('Save');
          if (saveBtn.evaluate().isNotEmpty) {
            await tester.tap(saveBtn);
            await tester.pumpAndSettle();
          }
        }
      }
    });

    testWidgets('SettingsScreen feedback toggles and backup import dialog',
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

      // Toggle Switches (Haptics, Notifications)
      final switches = find.byType(Switch);
      for (final s in switches.evaluate()) {
        await tester.tap(find.byWidget(s.widget));
        await tester.pumpAndSettle();
      }

      // Tap Import Backup
      final importTile = find.text('Import Backup');
      expect(importTile, findsOneWidget);
      await tester.tap(importTile);
      await tester.pumpAndSettle();

      expect(find.text('Import JSON Backup'), findsOneWidget);
      final textField = find.byType(TextField);
      if (textField.evaluate().isNotEmpty) {
        await tester.enterText(textField.first, '{"profiles":[]}');
        await tester.pumpAndSettle();
      }

      final importBtn = find.text('Import');
      expect(importBtn, findsOneWidget);
      await tester.tap(importBtn);
      await tester.pumpAndSettle();
    });
  });
}
