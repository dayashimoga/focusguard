import 'enums.dart';

/// Capability Matrix entry mapping OS features, requirements, enforcement levels, and verification status.
class CapabilityMatrixEntry {
  final String feature;
  final String androidSupport;
  final String iosSupport;
  final String requirement;
  final String enforcementLevel;
  final VerificationClassification verified;
  final String testId;
  final String evidenceArtifact;
  final String executionEnvironment;
  final int timestampMs;
  final String notes;

  const CapabilityMatrixEntry({
    required this.feature,
    required this.androidSupport,
    required this.iosSupport,
    required this.requirement,
    required this.enforcementLevel,
    required this.verified,
    this.testId = 'N/A',
    this.evidenceArtifact = 'N/A',
    this.executionEnvironment = 'clean_container',
    this.timestampMs = 0,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'feature': feature,
      'androidSupport': androidSupport,
      'iosSupport': iosSupport,
      'requirement': requirement,
      'enforcementLevel': enforcementLevel,
      'verified': verified.name,
      'testId': testId,
      'evidenceArtifact': evidenceArtifact,
      'executionEnvironment': executionEnvironment,
      'timestampMs': timestampMs,
      'notes': notes,
    };
  }

  factory CapabilityMatrixEntry.fromMap(Map<String, dynamic> map) {
    return CapabilityMatrixEntry(
      feature: map['feature'] as String,
      androidSupport: map['androidSupport'] as String,
      iosSupport: map['iosSupport'] as String,
      requirement: map['requirement'] as String,
      enforcementLevel: map['enforcementLevel'] as String,
      verified: VerificationClassification.values.firstWhere(
        (e) => e.name == map['verified'],
        orElse: () => VerificationClassification.IMPLEMENTED_UNVERIFIED,
      ),
      testId: map['testId'] as String? ?? 'N/A',
      evidenceArtifact: map['evidenceArtifact'] as String? ?? 'N/A',
      executionEnvironment:
          map['executionEnvironment'] as String? ?? 'clean_container',
      timestampMs: map['timestampMs'] as int? ?? 0,
      notes: map['notes'] as String? ?? '',
    );
  }
}
