/// Immutable audit journal entry documenting all session, safety, and security events.
class AuditEntry {
  final String id;
  final int timestampMs;
  final String eventType;
  final String description;
  final String? sessionId;
  final Map<String, dynamic>? metadata;

  const AuditEntry({
    required this.id,
    required this.timestampMs,
    required this.eventType,
    required this.description,
    this.sessionId,
    this.metadata,
  });

  DateTime get timestamp => DateTime.fromMillisecondsSinceEpoch(timestampMs);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestampMs': timestampMs,
      'eventType': eventType,
      'description': description,
      'sessionId': sessionId,
    };
  }

  factory AuditEntry.fromMap(Map<String, dynamic> map) {
    return AuditEntry(
      id: map['id'] as String,
      timestampMs: (map['timestampMs'] as num).toInt(),
      eventType: map['eventType'] as String,
      description: map['description'] as String,
      sessionId: map['sessionId'] as String?,
    );
  }
}
