import '../domain/models/focus_session.dart';
import 'database_helper.dart';

/// Repository for persisting and querying focus sessions.
class SessionRepository {
  final DatabaseHelper db;

  SessionRepository({DatabaseHelper? databaseHelper})
      : db = databaseHelper ?? DatabaseHelper.instance;

  Future<void> saveSession(FocusSession session) async {
    await db.insertSession(session.toMap());
  }

  Future<void> updateSession(FocusSession session) async {
    await db.updateSession(session.toMap());
  }

  Future<FocusSession?> getSessionById(String id) async {
    final map = await db.getSession(id);
    return map != null ? FocusSession.fromMap(map) : null;
  }

  Future<FocusSession?> getActiveSession() async {
    final map = await db.getActiveSession();
    return map != null ? FocusSession.fromMap(map) : null;
  }

  Future<List<FocusSession>> getAllSessions() async {
    final list = await db.getAllSessions();
    return list.map((m) => FocusSession.fromMap(m)).toList();
  }
}
