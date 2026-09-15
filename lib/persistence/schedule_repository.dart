import '../domain/models/focus_schedule.dart';
import 'database_helper.dart';

/// Repository for recurring focus schedules.
class ScheduleRepository {
  final DatabaseHelper db;

  ScheduleRepository({DatabaseHelper? databaseHelper})
      : db = databaseHelper ?? DatabaseHelper.instance;

  Future<void> saveSchedule(FocusSchedule schedule) async {
    await db.insertSchedule(schedule.toMap());
  }

  Future<void> updateSchedule(FocusSchedule schedule) async {
    await db.updateSchedule(schedule.toMap());
  }

  Future<void> deleteSchedule(String id) async {
    await db.deleteSchedule(id);
  }

  Future<List<FocusSchedule>> getAllSchedules() async {
    final list = await db.getAllSchedules();
    return list.map((m) => FocusSchedule.fromMap(m)).toList();
  }
}
