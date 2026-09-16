import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/domain/models/degradation_report.dart';

void main() {
  group('Domain: DegradationReport', () {
    test('instantiates healthy degradation report', () {
      final healthy = DegradationReport.healthy(timestampMs: 12345);
      expect(healthy.isDegraded, isFalse);
      expect(healthy.missingPermissions, isEmpty);
      expect(healthy.affectedMechanisms, isEmpty);
      expect(healthy.remediationInstructions, isEmpty);
      expect(healthy.timestampMs, equals(12345));
      expect(healthy.toString(), contains('HEALTHY'));
    });

    test(
        'instantiates degraded report with specific permissions and mechanisms',
        () {
      final degraded = DegradationReport.degraded(
        missingPermissions: ['PACKAGE_USAGE_STATS', 'SYSTEM_ALERT_WINDOW'],
        affectedMechanisms: [
          'Foreground app detection disabled',
          'Overlay disabled'
        ],
        remediationInstructions: ['Enable Usage Access', 'Enable Overlay'],
        timestampMs: 54321,
      );

      expect(degraded.isDegraded, isTrue);
      expect(degraded.missingPermissions.length, equals(2));
      expect(degraded.affectedMechanisms.first,
          contains('Foreground app detection'));
      expect(degraded.remediationInstructions.last, contains('Enable Overlay'));
      expect(degraded.toString(), contains('DEGRADED'));
    });

    test('serializes to and from Map accurately', () {
      final report = DegradationReport.degraded(
        missingPermissions: ['PACKAGE_USAGE_STATS'],
        affectedMechanisms: ['Detection disabled'],
        remediationInstructions: ['Open Settings'],
        timestampMs: 99999,
      );

      final map = report.toMap();
      expect(map['isDegraded'], isTrue);
      expect(map['timestampMs'], equals(99999));

      final restored = DegradationReport.fromMap(map);
      expect(restored.isDegraded, isTrue);
      expect(restored.missingPermissions, contains('PACKAGE_USAGE_STATS'));
      expect(restored.affectedMechanisms, contains('Detection disabled'));
      expect(restored.remediationInstructions, contains('Open Settings'));
      expect(restored.timestampMs, equals(99999));
    });

    test('fromMap handles empty or missing keys gracefully', () {
      final restored = DegradationReport.fromMap({});
      expect(restored.isDegraded, isFalse);
      expect(restored.missingPermissions, isEmpty);
      expect(restored.affectedMechanisms, isEmpty);
    });
  });
}
