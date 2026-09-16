/// Domain model capturing enforcement health and permission degradation state.
class DegradationReport {
  /// Whether enforcement capabilities are degraded due to missing permissions or service failure.
  final bool isDegraded;

  /// Identifiers of missing or revoked permissions (e.g. PACKAGE_USAGE_STATS, SYSTEM_ALERT_WINDOW).
  final List<String> missingPermissions;

  /// Specific enforcement mechanisms affected by the degradation.
  final List<String> affectedMechanisms;

  /// Actionable remediation instructions guiding the user to restore protection.
  final List<String> remediationInstructions;

  /// Timestamp in milliseconds since epoch when degradation was evaluated.
  final int timestampMs;

  const DegradationReport({
    required this.isDegraded,
    this.missingPermissions = const [],
    this.affectedMechanisms = const [],
    this.remediationInstructions = const [],
    required this.timestampMs,
  });

  /// Factory representing an optimal, fully healthy enforcement state.
  factory DegradationReport.healthy({int? timestampMs}) {
    return DegradationReport(
      isDegraded: false,
      missingPermissions: const [],
      affectedMechanisms: const [],
      remediationInstructions: const [],
      timestampMs: timestampMs ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Factory representing a degraded state with specific missing permissions.
  factory DegradationReport.degraded({
    required List<String> missingPermissions,
    required List<String> affectedMechanisms,
    required List<String> remediationInstructions,
    int? timestampMs,
  }) {
    return DegradationReport(
      isDegraded: true,
      missingPermissions: List.unmodifiable(missingPermissions),
      affectedMechanisms: List.unmodifiable(affectedMechanisms),
      remediationInstructions: List.unmodifiable(remediationInstructions),
      timestampMs: timestampMs ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isDegraded': isDegraded,
      'missingPermissions': missingPermissions,
      'affectedMechanisms': affectedMechanisms,
      'remediationInstructions': remediationInstructions,
      'timestampMs': timestampMs,
    };
  }

  factory DegradationReport.fromMap(Map<String, dynamic> map) {
    return DegradationReport(
      isDegraded: map['isDegraded'] as bool? ?? false,
      missingPermissions:
          List<String>.from(map['missingPermissions'] as List? ?? []),
      affectedMechanisms:
          List<String>.from(map['affectedMechanisms'] as List? ?? []),
      remediationInstructions:
          List<String>.from(map['remediationInstructions'] as List? ?? []),
      timestampMs:
          map['timestampMs'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  String toString() {
    if (!isDegraded) return 'DegradationReport(HEALTHY)';
    return 'DegradationReport(DEGRADED: missing=$missingPermissions, affected=$affectedMechanisms)';
  }
}
