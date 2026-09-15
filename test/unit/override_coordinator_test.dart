import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/core/security/pin_hasher.dart';
import 'package:focusguard/domain/models/enums.dart';
import 'package:focusguard/domain/models/override_policy.dart';
import 'package:focusguard/engine/override_coordinator.dart';

void main() {
  group('Engine: OverrideCoordinator', () {
    test('validates immediate override according to policy and quota', () {
      const allowedPolicy = OverridePolicy(
        enabledOverrideTypes: [OverrideType.immediate],
        maxOverridesPerDay: 2,
        usedOverridesToday: 0,
      );
      final coordinator = OverrideCoordinator(policy: allowedPolicy);
      expect(coordinator.validateImmediateOverride().isSuccessful, isTrue);

      const exhaustedPolicy = OverridePolicy(
        enabledOverrideTypes: [OverrideType.immediate],
        maxOverridesPerDay: 2,
        usedOverridesToday: 2,
      );
      final exhaustedCoord = OverrideCoordinator(policy: exhaustedPolicy);
      final res = exhaustedCoord.validateImmediateOverride();
      expect(res.isSuccessful, isFalse);
      expect(res.errorMessage, contains('quota'));

      const disabledPolicy = OverridePolicy(
        enabledOverrideTypes: [OverrideType.emergency],
      );
      final disabledCoord = OverrideCoordinator(policy: disabledPolicy);
      expect(disabledCoord.validateImmediateOverride().isSuccessful, isFalse);
    });

    test('emergency override is always permitted for safety', () {
      final coordinator = OverrideCoordinator(policy: const OverridePolicy());
      final res = coordinator.validateEmergencyOverride();
      expect(res.isSuccessful, isTrue);
      expect(res.type, equals(OverrideType.emergency));
    });

    test('validates confirmation phrase matching and mandatory typed reason',
        () {
      const policy = OverridePolicy(
        enabledOverrideTypes: [OverrideType.confirmationPhrase],
        confirmationPhrase: 'I choose to exit',
        requireReason: true,
      );
      final coordinator = OverrideCoordinator(policy: policy);

      // Exact match with valid reason
      final ok = coordinator.validateConfirmationPhrase(
        candidatePhrase: 'I choose to exit',
        reason: 'Urgent family call',
      );
      expect(ok.isSuccessful, isTrue);

      // Mismatched phrase
      final mismatch = coordinator.validateConfirmationPhrase(
        candidatePhrase: 'Wrong phrase',
        reason: 'Urgent family call',
      );
      expect(mismatch.isSuccessful, isFalse);
      expect(mismatch.errorMessage, contains('does not match'));

      // Too short reason (< 5 chars)
      final shortReason = coordinator.validateConfirmationPhrase(
        candidatePhrase: 'I choose to exit',
        reason: 'no',
      );
      expect(shortReason.isSuccessful, isFalse);
      expect(shortReason.errorMessage, contains('at least 5 characters'));
    });

    test('validates salted PIN verification', () {
      const pin = '5678';
      final salt = PinHasher.generateSalt();
      final hash = PinHasher.hashPin(pin, salt);

      const policy = OverridePolicy(
        enabledOverrideTypes: [OverrideType.pinProtected],
        isPinRequired: true,
        requireReason: true,
      );

      final coordinator = OverrideCoordinator(
        policy: policy,
        storedPinHash: hash,
        storedPinSalt: salt,
      );

      // Correct PIN with valid reason
      final ok =
          coordinator.validatePin(candidatePin: pin, reason: 'Meeting started');
      expect(ok.isSuccessful, isTrue);

      // Incorrect PIN
      final wrong = coordinator.validatePin(
          candidatePin: '0000', reason: 'Meeting started');
      expect(wrong.isSuccessful, isFalse);
      expect(wrong.errorMessage, contains('Incorrect PIN'));
    });
  });
}
