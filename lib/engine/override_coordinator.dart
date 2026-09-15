import 'dart:async';
import '../core/security/pin_hasher.dart';
import '../domain/models/enums.dart';
import '../domain/models/override_policy.dart';

/// Result of an override attempt.
class OverrideValidationResult {
  final bool isSuccessful;
  final String? errorMessage;
  final OverrideType type;

  const OverrideValidationResult({
    required this.isSuccessful,
    this.errorMessage,
    required this.type,
  });

  factory OverrideValidationResult.success(OverrideType type) =>
      OverrideValidationResult(isSuccessful: true, type: type);

  factory OverrideValidationResult.failure(OverrideType type, String message) =>
      OverrideValidationResult(
          isSuccessful: false, errorMessage: message, type: type);
}

/// Coordinates unlock friction, verification, and audit logging for session overrides.
class OverrideCoordinator {
  final OverridePolicy policy;
  final String? storedPinHash;
  final String? storedPinSalt;

  OverrideCoordinator({
    required this.policy,
    this.storedPinHash,
    this.storedPinSalt,
  });

  /// Evaluates whether an immediate override is permitted.
  OverrideValidationResult validateImmediateOverride() {
    if (!policy.enabledOverrideTypes.contains(OverrideType.immediate)) {
      return OverrideValidationResult.failure(
        OverrideType.immediate,
        'Immediate override is disabled under current focus profile',
      );
    }
    if (policy.isQuotaExhausted) {
      return OverrideValidationResult.failure(
        OverrideType.immediate,
        'Daily override quota has been exhausted (${policy.maxOverridesPerDay}/${policy.maxOverridesPerDay})',
      );
    }
    return OverrideValidationResult.success(OverrideType.immediate);
  }

  /// Evaluates whether an emergency bypass is valid. Emergency is always permitted by design!
  OverrideValidationResult validateEmergencyOverride() {
    return OverrideValidationResult.success(OverrideType.emergency);
  }

  /// Validates a typed safety confirmation phrase.
  OverrideValidationResult validateConfirmationPhrase({
    required String candidatePhrase,
    required String? reason,
  }) {
    if (!policy.enabledOverrideTypes
        .contains(OverrideType.confirmationPhrase)) {
      return OverrideValidationResult.failure(
        OverrideType.confirmationPhrase,
        'Confirmation phrase override is not enabled',
      );
    }
    if (policy.isQuotaExhausted) {
      return OverrideValidationResult.failure(
        OverrideType.confirmationPhrase,
        'Daily override quota has been exhausted',
      );
    }
    if (policy.requireReason && (reason == null || reason.trim().length < 5)) {
      return OverrideValidationResult.failure(
        OverrideType.confirmationPhrase,
        'A typed explanation of at least 5 characters is required',
      );
    }
    if (candidatePhrase.trim() != policy.confirmationPhrase.trim()) {
      return OverrideValidationResult.failure(
        OverrideType.confirmationPhrase,
        'The entered phrase does not match the safety confirmation phrase',
      );
    }
    return OverrideValidationResult.success(OverrideType.confirmationPhrase);
  }

  /// Validates a candidate PIN against stored salted hash.
  OverrideValidationResult validatePin({
    required String candidatePin,
    required String? reason,
  }) {
    if (!policy.isPinRequired ||
        storedPinHash == null ||
        storedPinSalt == null) {
      return OverrideValidationResult.failure(
        OverrideType.pinProtected,
        'PIN protection is not configured',
      );
    }
    if (policy.isQuotaExhausted) {
      return OverrideValidationResult.failure(
        OverrideType.pinProtected,
        'Daily override quota has been exhausted',
      );
    }
    if (policy.requireReason && (reason == null || reason.trim().length < 5)) {
      return OverrideValidationResult.failure(
        OverrideType.pinProtected,
        'A typed explanation of at least 5 characters is required',
      );
    }
    final isMatch = PinHasher.verifyPin(
      candidatePin: candidatePin,
      salt: storedPinSalt!,
      expectedHash: storedPinHash!,
    );
    if (!isMatch) {
      return OverrideValidationResult.failure(
        OverrideType.pinProtected,
        'Incorrect PIN entered',
      );
    }
    return OverrideValidationResult.success(OverrideType.pinProtected);
  }

  /// Starts a countdown stream for delayed cooldown override.
  Stream<int> startCooldownStream() async* {
    for (int remaining = policy.cooldownSeconds; remaining >= 0; remaining--) {
      yield remaining;
      if (remaining > 0) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }
}
