import 'package:flutter/material.dart';
import 'app.dart';
import 'engine/daily_limit_tracker.dart';
import 'engine/focus_engine.dart';
import 'persistence/audit_repository.dart';
import 'persistence/database_helper.dart';
import 'persistence/profile_repository.dart';
import 'persistence/schedule_repository.dart';
import 'persistence/session_repository.dart';
import 'persistence/settings_repository.dart';
import 'platform/method_channel_bridge.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistence layer
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.initDatabase();

  final sessionRepo = SessionRepository(databaseHelper: dbHelper);
  final profileRepo = ProfileRepository(databaseHelper: dbHelper);
  final scheduleRepo = ScheduleRepository(databaseHelper: dbHelper);
  final auditRepo = AuditRepository(databaseHelper: dbHelper);
  final settingsRepo = SettingsRepository(databaseHelper: dbHelper);

  await profileRepo.initProfiles();

  final platformBridge = MethodChannelPlatformBridge();
  final dailyLimitTracker = DailyLimitTracker();

  final focusEngine = FocusEngine(
    platformBridge: platformBridge,
  );

  // Check if an active session was interrupted (e.g. process restart / reboot)
  final activeSavedSession = await sessionRepo.getActiveSession();
  if (activeSavedSession != null) {
    await focusEngine.restoreInterruptedSession(activeSavedSession);
  }

  runApp(
    FocusGuardApp(
      focusEngine: focusEngine,
      sessionRepository: sessionRepo,
      profileRepository: profileRepo,
      scheduleRepository: scheduleRepo,
      auditRepository: auditRepo,
      settingsRepository: settingsRepo,
      dailyLimitTracker: dailyLimitTracker,
      platformBridge: platformBridge,
    ),
  );
}
