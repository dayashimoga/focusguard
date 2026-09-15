import 'enums.dart';

/// Capability Matrix entry mapping OS features, requirements, enforcement levels, and verification status.
class CapabilityMatrixEntry {
  final String feature;
  final String androidSupport;
  final String iosSupport;
  final String requirement;
  final String enforcementLevel;
  final VerificationClassification verified;
  final String notes;

  const CapabilityMatrixEntry({
    required this.feature,
    required this.androidSupport,
    required this.iosSupport,
    required this.requirement,
    required this.enforcementLevel,
    required this.verified,
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
      notes: map['notes'] as String? ?? '',
    );
  }
}
