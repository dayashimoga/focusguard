import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/core/security/pin_hasher.dart';
import 'package:focusguard/domain/models/enums.dart';
import 'package:focusguard/domain/models/focus_profile.dart';
import 'package:focusguard/domain/models/override_policy.dart';
import 'package:focusguard/engine/focus_engine.dart';
import 'package:focusguard/platform/platform_bridge.dart';
import 'package:focusguard/presentation/widgets/exit_focus_dialog.dart';

class MockWidgetBridge extends Fake implements PlatformBridge {
  @override
  Future<Map<String, dynamic>> getCapabilities() async => {
        'platform': 'mock_bridge',
        'hasUsageStats': true,
        'hasOverlay': true,
      };

  @override
  Future<int> getMonotonicElapsedRealtime() async => 1000000;

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
}

void main() {
  group('ExitFocusDialog Comprehensive Widget Tests', () {
    late FocusEngine engine;
    late MockWidgetBridge bridge;

    setUp(() {
      bridge = MockWidgetBridge();
    });

    testWidgets('Renders immediate override dialog and allows exit',
        (tester) async {
      engine = FocusEngine(
        platformBridge: bridge,
        overridePolicy: const OverridePolicy(
          enabledOverrideTypes: [OverrideType.immediate],
          requireReason: false,
          cooldownSeconds: 0,
        ),
      );

      const profile = FocusProfile(
        id: 'imm_p',
        name: 'Immediate Profile',
        description: 'Profile for testing immediate exit',
        iconName: 'shield',
        restrictionStrength: RestrictionStrength.focus,
        blockedPackageNames: ['com.distraction.app'],
      );
      await engine.startSession(
          profile: profile, durationMinutes: 15, gracePeriodSeconds: 0);

      bool exitSuccessCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExitFocusDialog(
              focusEngine: engine,
              onExitSuccess: () {
                exitSuccessCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Exit Focus Session'), findsOneWidget);
      expect(
          find.textContaining('Immediate exit confirmation'), findsOneWidget);

      final confirmBtn = find.text('Confirm & End Session');
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(exitSuccessCalled, isTrue);
      expect(engine.currentState, equals(SessionState.overridden));
      engine.dispose();
    });

    testWidgets(
        'Renders phrase mode, handles copy phrase, invalid input, and cancel',
        (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async => null,
      );
      engine = FocusEngine(
        platformBridge: bridge,
        overridePolicy: const OverridePolicy(
          enabledOverrideTypes: [OverrideType.confirmationPhrase],
          confirmationPhrase: 'I deliberately choose to exit focus',
          requireReason: false,
          cooldownSeconds: 0,
        ),
      );

      const profile = FocusProfile(
        id: 'phrase_p',
        name: 'Phrase Profile',
        description: 'Profile for testing phrase exit',
        iconName: 'shield',
        restrictionStrength: RestrictionStrength.focus,
        blockedPackageNames: ['com.distraction.app'],
      );
      await engine.startSession(
          profile: profile, durationMinutes: 15, gracePeriodSeconds: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExitFocusDialog(focusEngine: engine),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Copy Phrase button
      final copyBtn = find.byTooltip('Copy phrase');
      expect(copyBtn, findsOneWidget);
      await tester.tap(copyBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Phrase copied to clipboard'), findsOneWidget);

      // Type incorrect phrase
      final phraseField = find.byType(TextField);
      expect(phraseField, findsOneWidget);
      await tester.enterText(phraseField, 'wrong phrase');
      await tester.pump();

      // Check inline message
      expect(
          find.text(
              'Phrase doesn\'t match. Type the confirmation phrase exactly.'),
          findsOneWidget);

      // Test Cancel button
      final cancelBtn = find.text('Keep Focusing');
      expect(cancelBtn, findsOneWidget);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Verify session remained active
      expect(engine.currentState, equals(SessionState.active));
      engine.dispose();
    });

    testWidgets('Renders combined PIN, Reason, and Delayed Cooldown dialog',
        (tester) async {
      final salt = PinHasher.generateSalt();
      final hash = PinHasher.hashPin('1234', salt);

      const policy = OverridePolicy(
        enabledOverrideTypes: [
          OverrideType.pinProtected,
          OverrideType.typedReason,
          OverrideType.delayedCooldown,
        ],
        isPinRequired: true,
        requireReason: true,
        cooldownSeconds: 2,
      );

      engine = FocusEngine(
        platformBridge: bridge,
        overridePolicy: policy,
      );
      engine.updateOverridePolicy(policy, pinHash: hash, pinSalt: salt);

      const profile = FocusProfile(
        id: 'combo_p',
        name: 'Combo Profile',
        description: 'Profile for testing combo exit',
        iconName: 'shield',
        restrictionStrength: RestrictionStrength.focus,
        blockedPackageNames: ['com.distraction.app'],
      );
      await engine.startSession(
          profile: profile, durationMinutes: 15, gracePeriodSeconds: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExitFocusDialog(focusEngine: engine),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify checklist items
      expect(find.textContaining('Reason (at least 5 characters)'),
          findsOneWidget);
      expect(find.text('○ Security PIN'), findsOneWidget);

      // Verify fields exist
      expect(find.byType(TextField), findsNWidgets(2)); // reason and pin

      // Enter short reason
      final reasonField =
          find.widgetWithText(TextField, 'Why do you need to break focus?');
      await tester.enterText(reasonField, 'abc');
      await tester.pump();
      expect(
          find.text('Please provide at least 5 characters.'), findsOneWidget);

      // Enter valid reason
      await tester.enterText(
          reasonField, 'Need to take urgent family phone call');
      await tester.pump();

      // Enter PIN
      final pinField = find.widgetWithText(TextField, 'Enter 4-digit PIN');
      await tester.enterText(pinField, '1234');
      await tester.pump();

      // Wait for 2-second cooldown
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Tap Confirm & End Session
      final confirmBtn = find.text('Confirm & End Session');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(engine.currentState, equals(SessionState.overridden));
      engine.dispose();
    });
  });
}
