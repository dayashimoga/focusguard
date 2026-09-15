import '../domain/models/audit_entry.dart';
import 'database_helper.dart';

/// Append-only repository for auditing session, safety, and security events.
class AuditRepository {
  final DatabaseHelper db;

  AuditRepository({DatabaseHelper? databaseHelper})
      : db = databaseHelper ?? DatabaseHelper.instance;

  Future<void> logEvent(AuditEntry entry) async {
    await db.insertAuditLog(entry.toMap());
  }

  Future<List<AuditEntry>> getAllLogs() async {
    final list = await db.getAllAuditLogs();
    final entries = list.map((m) => AuditEntry.fromMap(m)).toList();
    entries
        .sort((a, b) => b.timestampMs.compareTo(a.timestampMs)); // newest first
    return entries;
  }
}
