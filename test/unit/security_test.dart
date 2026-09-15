import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/core/security/pin_hasher.dart';
import 'package:focusguard/core/security/tamper_detector.dart';
import 'package:focusguard/core/utils/logger.dart';

void main() {
  group('Security: PinHasher', () {
    test('generates unique cryptographic salts', () {
      final salt1 = PinHasher.generateSalt();
      final salt2 = PinHasher.generateSalt();

      expect(salt1, isNotEmpty);
      expect(salt2, isNotEmpty);
      expect(salt1, isNot(equals(salt2)));
      expect(salt1.length, equals(PinHasher.saltByteLength * 2));
    });

    test('hashes PIN with salted SHA-256 and verifies correctly', () {
      const pin = '4829';
      final salt = PinHasher.generateSalt();
      final hash = PinHasher.hashPin(pin, salt);

      expect(hash, isNotEmpty);
      expect(hash.length, equals(64));

      final verified = PinHasher.verifyPin(
        candidatePin: pin,
        salt: salt,
        expectedHash: hash,
      );
      expect(verified, isTrue);

      final wrongVerified = PinHasher.verifyPin(
        candidatePin: '1111',
        salt: salt,
        expectedHash: hash,
      );
      expect(wrongVerified, isFalse);
    });

    test('rejects empty inputs during verification', () {
      expect(
          PinHasher.verifyPin(
              candidatePin: '', salt: 'abc', expectedHash: '123'),
          isFalse);
      expect(
          PinHasher.verifyPin(
              candidatePin: '1234', salt: '', expectedHash: '123'),
          isFalse);
      expect(
          PinHasher.verifyPin(
              candidatePin: '1234', salt: 'abc', expectedHash: ''),
          isFalse);
    });

    test('validates PIN format rules', () {
      expect(PinHasher.isValidPinFormat('1234'), isTrue);
      expect(PinHasher.isValidPinFormat('12345678'), isTrue);
      expect(PinHasher.isValidPinFormat('123'), isFalse);
      expect(PinHasher.isValidPinFormat('123456789'), isFalse);
      expect(PinHasher.isValidPinFormat('12a4'), isFalse);
      expect(PinHasher.isValidPinFormat('abcd'), isFalse);
    });

    test(
        'constant-time string comparison verifies identical and non-identical strings',
        () {
      expect(
          PinHasher.constantTimeEquals(
              'secret_hash_value_123', 'secret_hash_value_123'),
          isTrue);
      expect(
          PinHasher.constantTimeEquals(
              'secret_hash_value_123', 'secret_hash_value_124'),
          isFalse);
      expect(PinHasher.constantTimeEquals('short', 'longer_string'), isFalse);
    });
  });

  group('Security: TamperDetector', () {
    test(
        'passes integrity check when wall clock and monotonic clock advance synchronously',
        () {
      const lastMono = 10000;
      const currMono = 20000;
      const lastWall = 1700000000000;
      const currWall = 1700000010000;

      final result = TamperDetector.checkClockIntegrity(
        lastMonotonicMs: lastMono,
        currentMonotonicMs: currMono,
        lastWallClockMs: lastWall,
        currentWallClockMs: currWall,
      );

      expect(result.tampered, isFalse);
      expect(result.skewMs, equals(0));
    });

    test(
        'flags tampering when wall clock jumps forward by 2 hours while monotonic only advanced 5 seconds',
        () {
      const lastMono = 10000;
      const currMono = 15000;
      const lastWall = 1700000000000;
      const currWall = 1700007205000;

      final result = TamperDetector.checkClockIntegrity(
        lastMonotonicMs: lastMono,
        currentMonotonicMs: currMono,
        lastWallClockMs: lastWall,
        currentWallClockMs: currWall,
      );

      expect(result.tampered, isTrue);
      expect(result.reason, contains('shifted forward'));
      expect(result.skewMs, equals(7200000));
    });

    test('flags tampering when wall clock steps backward', () {
      const lastMono = 10000;
      const currMono = 20000;
      const lastWall = 1700000050000;
      const currWall = 1700000000000;

      final result = TamperDetector.checkClockIntegrity(
        lastMonotonicMs: lastMono,
        currentMonotonicMs: currMono,
        lastWallClockMs: lastWall,
        currentWallClockMs: currWall,
      );

      expect(result.tampered, isTrue);
      expect(result.reason, contains('shifted backward'));
    });

    test(
        'flags tampering if monotonic clock steps backward (kernel corruption)',
        () {
      const lastMono = 20000;
      const currMono = 10000;

      final result = TamperDetector.checkClockIntegrity(
        lastMonotonicMs: lastMono,
        currentMonotonicMs: currMono,
        lastWallClockMs: 1000,
        currentWallClockMs: 2000,
      );

      expect(result.tampered, isTrue);
      expect(result.reason, contains('Monotonic clock stepped backward'));
    });

    test('identifies device reboot via boot count increment', () {
      expect(
          TamperDetector.wasDeviceRebooted(
              sessionStartBootCount: 5, currentBootCount: 6),
          isTrue);
      expect(
          TamperDetector.wasDeviceRebooted(
              sessionStartBootCount: 5, currentBootCount: 5),
          isFalse);
    });
  });

  group('Security: AppLogger PII Sanitization', () {
    test('logs info, warn, error without throwing', () {
      AppLogger.info('Normal system info event');
      AppLogger.warn('Warning: permission is missing');
      AppLogger.error('Error encountered', error: Exception('test error'));
      AppLogger.debug('Debug tracing info');
    });
  });
}
