import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Cryptographically secure PIN hasher and verifier.
/// Implements salted SHA-256 with constant-time equality check to prevent timing attacks.
class PinHasher {
  PinHasher._();

  static const int saltByteLength = 16;

  /// Generates a cryptographically random hexadecimal salt.
  static String generateSalt() {
    final random = Random.secure();
    final bytes =
        List<int>.generate(saltByteLength, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hashes a user PIN with the provided salt using SHA-256.
  static String hashPin(String pin, String salt) {
    if (pin.isEmpty) {
      throw ArgumentError('PIN cannot be empty');
    }
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  /// Verifies a candidate PIN against a known hash and salt in constant time.
  static bool verifyPin({
    required String candidatePin,
    required String salt,
    required String expectedHash,
  }) {
    if (candidatePin.isEmpty || salt.isEmpty || expectedHash.isEmpty) {
      return false;
    }
    final candidateHash = hashPin(candidatePin, salt);
    return constantTimeEquals(candidateHash, expectedHash);
  }

  /// Constant-time string comparison to defend against timing side-channel analysis.
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Validates PIN format: 4 to 8 numeric digits.
  static bool isValidPinFormat(String pin) {
    if (pin.length < 4 || pin.length > 8) {
      return false;
    }
    return RegExp(r'^\d+$').hasMatch(pin);
  }
}
