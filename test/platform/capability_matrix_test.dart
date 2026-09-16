import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/domain/models/enums.dart';
import 'package:focusguard/platform/capability_matrix.dart';

void main() {
  group('Platform: CapabilityMatrix', () {
    test('contains all 8 required capability areas from specification', () {
      final matrix = CapabilityMatrix.getMatrix(
        isAndroid: true,
        hasUsageAccess: true,
        hasOverlay: true,
        hasAccessibility: false,
        isDeviceOwner: false,
      );

      expect(matrix.length, equals(8));

      final featureNames = matrix.map((e) => e.feature).toList();
      expect(featureNames, contains('Foreground App Detection'));
      expect(featureNames, contains('Real-Time Interception Barrier'));
      expect(featureNames, contains('Zero-Latency App Switch Block'));
      expect(featureNames, contains('Device-Owner Kiosk / LockTask Mode'));
      expect(featureNames, contains('Monotonic Tamper-Resistant Clock'));
      expect(featureNames, contains('Notification Suppression (DND)'));
      expect(featureNames, contains('Reboot & Crash Recovery'));
      expect(featureNames, contains('Emergency Access Exemption'));
    });

    test('honestly classifies iOS accessibility as PLATFORM_UNSUPPORTED', () {
      final matrix = CapabilityMatrix.getMatrix(isAndroid: false);
      final accessibilityEntry = matrix.firstWhere(
          (e) => e.feature.contains('Zero-Latency App Switch Block'));

      expect(accessibilityEntry.verified,
          equals(VerificationClassification.PLATFORM_UNSUPPORTED));
      expect(accessibilityEntry.iosSupport, contains('Unsupported'));
    });

    test('marks Device Owner as HARDWARE_REQUIRED when not provisioned', () {
      final matrix = CapabilityMatrix.getMatrix(isDeviceOwner: false);
      final kioskEntry =
          matrix.firstWhere((e) => e.feature.contains('Device-Owner'));

      expect(kioskEntry.verified,
          equals(VerificationClassification.HARDWARE_REQUIRED));
    });

    test(
        'marks Monotonic Clock and Emergency Exemption as permanently VERIFIED with evidence',
        () {
      final matrix = CapabilityMatrix.getMatrix();
      final mono = matrix.firstWhere((e) => e.feature.contains('Monotonic'));
      final emergency =
          matrix.firstWhere((e) => e.feature.contains('Emergency'));

      expect(mono.verified, equals(VerificationClassification.VERIFIED));
      expect(mono.testId, equals('MONO-001'));
      expect(mono.evidenceArtifact, contains('e2e_enforcement_evidence.json'));

      expect(emergency.verified, equals(VerificationClassification.VERIFIED));
      expect(emergency.testId, equals('EMERG-001'));
    });

    test(
        'classifies iOS Screen Time without FamilyControls as EXTERNAL_ENTITLEMENT_REQUIRED',
        () {
      final matrix = CapabilityMatrix.getMatrix(
          isAndroid: false, hasFamilyControls: false);
      final detectionEntry = matrix
          .firstWhere((e) => e.feature.contains('Foreground App Detection'));
      expect(detectionEntry.verified,
          equals(VerificationClassification.EXTERNAL_ENTITLEMENT_REQUIRED));
    });
  });
}
