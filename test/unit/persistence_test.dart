import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/domain/models/audit_entry.dart';
import 'package:focusguard/domain/models/enums.dart';
import 'package:focusguard/domain/models/focus_profile.dart';
import 'package:focusguard/domain/models/focus_schedule.dart';
import 'package:focusguard/domain/models/focus_session.dart';
import 'package:focusguard/persistence/audit_repository.dart';
import 'package:focusguard/persistence/database_helper.dart';
import 'package:focusguard/persistence/profile_repository.dart';
import 'package:focusguard/persistence/schedule_repository.dart';
import 'package:focusguard/persistence/session_repository.dart';
import 'package:focusguard/persistence/settings_repository.dart';

void main() {
  late DatabaseHelper db;
  late SessionRepository sessionRepo;
  late ProfileRepository profileRepo;
  late ScheduleRepository scheduleRepo;
  late AuditRepository auditRepo;
  late SettingsRepository settingsRepo;

  setUp(() async {
    db = DatabaseHelper.instance;
    await db.clearAllData();
    sessionRepo = SessionRepository(databaseHelper: db);
    profileRepo = ProfileRepository(databaseHelper: db);
    scheduleRepo = ScheduleRepository(databaseHelper: db);
    auditRepo = AuditRepository(databaseHelper: db);
    settingsRepo = SettingsRepository(databaseHelper: db);
  });

  group('Persistence: SessionRepository', () {
    test('saves, retrieves, and updates focus sessions', () async {
      const session = FocusSession(
        id: 'sess_1',
        profileId: 'preset_deep_work',
        profileName: 'Deep Work',
        restrictionStrength: RestrictionStrength.deepFocus,
        totalDurationSeconds: 1800,
        monotonicStartMs: 1000,
        monotonicTargetMs: 1801000,
        wallClockStartMs: 1700000000000,
        wallClockTargetMs: 1700001800000,
        state: SessionState.active,
      );

      await sessionRepo.saveSession(session);

      final retrieved = await sessionRepo.getSessionById('sess_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.profileName, equals('Deep Work'));
      expect(retrieved.state, equals(SessionState.active));

      final active = await sessionRepo.getActiveSession();
      expect(active, isNotNull);
      expect(active!.id, equals('sess_1'));

      final updated = session.copyWith(state: SessionState.completed);
      await sessionRepo.updateSession(updated);

      final activeAfterComplete = await sessionRepo.getActiveSession();
      expect(activeAfterComplete, isNull);
    });
  });

  group('Persistence: ProfileRepository', () {
    test('initializes default presets and manages custom profiles', () async {
      await profileRepo.initProfiles();

      final profiles = await profileRepo.getAllProfiles();
      expect(profiles.length, greaterThanOrEqualTo(5));

      final defaultProf = await profileRepo.getDefaultProfile();
      expect(defaultProf, isNotNull);
      expect(defaultProf!.name, equals('Deep Work'));

      const custom = FocusProfile(
        id: 'custom_1',
        name: 'Coding Focus',
        description: 'No social media while compiling',
        iconName: 'code',
        restrictionStrength: RestrictionStrength.strict,
      );

      await profileRepo.saveProfile(custom);
      final allWithCustom = await profileRepo.getAllProfiles();
      expect(allWithCustom.any((p) => p.id == 'custom_1'), isTrue);

      await profileRepo.deleteProfile('custom_1');
      final afterDelete = await profileRepo.getAllProfiles();
      expect(afterDelete.any((p) => p.id == 'custom_1'), isFalse);
    });
  });

  group('Persistence: ScheduleRepository', () {
    test('saves, queries, and deletes recurring schedules', () async {
      const schedule = FocusSchedule(
        id: 'sched_1',
        profileId: 'preset_study',
        name: 'Evening Study',
        startHour: 19,
        startMinute: 0,
        endHour: 21,
        endMinute: 0,
        daysOfWeek: [1, 3, 5],
      );

      await scheduleRepo.saveSchedule(schedule);

      final list = await scheduleRepo.getAllSchedules();
      expect(list.length, equals(1));
      expect(list.first.name, equals('Evening Study'));

      await scheduleRepo.deleteSchedule('sched_1');
      final emptyList = await scheduleRepo.getAllSchedules();
      expect(emptyList.isEmpty, isTrue);
    });
  });

  group('Persistence: AuditRepository', () {
    test('logs audit events and retrieves in chronological order', () async {
      final entry1 = AuditEntry(
        id: '1',
        timestampMs: 1000,
        eventType: 'session_start',
        description: 'Session started',
      );
      final entry2 = AuditEntry(
        id: '2',
        timestampMs: 2000,
        eventType: 'session_complete',
        description: 'Session completed',
      );

      await auditRepo.logEvent(entry1);
      await auditRepo.logEvent(entry2);

      final logs = await auditRepo.getAllLogs();
      expect(logs.length, equals(2));
      expect(logs.first.eventType, equals('session_complete')); // Newest first
    });
  });

  group('Persistence: SettingsRepository', () {
    test('manages theme, PIN, and JSON backup export/import', () async {
      expect(await settingsRepo.getThemeMode(), equals('dark'));
      await settingsRepo.setThemeMode('light');
      expect(await settingsRepo.getThemeMode(), equals('light'));

      // PIN setup & verification
      expect(await settingsRepo.hasPinConfigured(), isFalse);
      final setOk = await settingsRepo.setPin('1234');
      expect(setOk, isTrue);
      expect(await settingsRepo.hasPinConfigured(), isTrue);
      expect(await settingsRepo.verifyPin('1234'), isTrue);
      expect(await settingsRepo.verifyPin('9999'), isFalse);

      await settingsRepo.removePin();
      expect(await settingsRepo.hasPinConfigured(), isFalse);

      // JSON backup export
      final jsonBackup = await settingsRepo.exportBackupJson();
      expect(jsonBackup, contains('version'));

      // JSON backup import
      final importOk = await settingsRepo.importBackupJson(jsonBackup);
      expect(importOk, isTrue);
    });
  });
}
