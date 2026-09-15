import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/domain/models/app_info.dart';
import 'package:focusguard/domain/models/enums.dart';
import 'package:focusguard/domain/models/focus_profile.dart';
import 'package:focusguard/engine/focus_engine.dart';
import 'package:focusguard/persistence/audit_repository.dart';
import 'package:focusguard/persistence/database_helper.dart';
import 'package:focusguard/persistence/session_repository.dart';
import 'package:focusguard/platform/platform_bridge.dart';

class IntegrationPlatformBridge implements PlatformBridge {
  bool enforcementActive = false;

  @override
  Future<Map<String, dynamic>> getCapabilities() async =>
      {'hasMonotonicClock': true};

  @override
  Future<int> getMonotonicElapsedRealtime() async => 10000;

  @override
  Future<int> getBootCount() async => 1;

  @override
  Future<bool> startEnforcement({
    required List<String> blockedPackages,
    required List<String> allowedPackages,
    required String restrictionLevel,
    required int targetElapsedRealtime,
    required int targetWallClock,
    required String profileName,
  }) async {
    enforcementActive = true;
    return true;
  }

  @override
  Future<bool> stopEnforcement() async {
    enforcementActive = false;
    return true;
  }

  @override
  Future<List<AppInfo>> getInstalledApps() async => [];

  @override
  Future<int> getAppDailyUsage(String packageName) async => 0;

  @override
  Future<bool> requestUsageStatsPermission() async => true;

  @override
  Future<bool> requestOverlayPermission() async => true;

  @override
  Future<bool> requestDndPermission() async => true;

  @override
  Future<bool> requestAccessibilitySettings() async => true;

  @override
  Future<bool> setDndFilter(bool enabled) async => true;
}

void main() {
  late DatabaseHelper db;
  late SessionRepository sessionRepo;
  late AuditRepository auditRepo;
  late IntegrationPlatformBridge bridge;
  late FocusEngine engine;

  setUp(() async {
    db = DatabaseHelper.instance;
    await db.clearAllData();
    sessionRepo = SessionRepository(databaseHelper: db);
    auditRepo = AuditRepository(databaseHelper: db);
    bridge = IntegrationPlatformBridge();

    engine = FocusEngine(platformBridge: bridge);

    // Wire engine audit stream to repository
    engine.auditStream.listen((entry) {
      auditRepo.logEvent(entry);
    });
  });

  tearDown(() {
    engine.dispose();
  });

  group('Integration: End-to-End Session Lifecycle', () {
    test(
        'starts session, logs start event, activates enforcement, takes break, and completes',
        () async {
      final profile = FocusProfile.defaultPresets.first;

      // 1. Start session
      final session = await engine.startSession(
        profile: profile,
        durationMinutes: 30,
        gracePeriodSeconds: 0,
      );

      await sessionRepo.saveSession(session);
      expect(bridge.enforcementActive, isTrue);
      expect(engine.currentState, equals(SessionState.active));

      // 2. Take break
      await engine.startBreak(5);
      expect(bridge.enforcementActive, isFalse);
      expect(engine.currentState, equals(SessionState.onBreak));

      // 3. Resume from break
      await engine.resumeFromBreak();
      expect(bridge.enforcementActive, isTrue);
      expect(engine.currentState, equals(SessionState.active));

      // 4. Record a distraction attempt
      engine.recordDistractionAttempt('com.instagram.android');
      expect(engine.currentSession!.distractionAttempts, equals(1));

      // 5. Override session with confirmation
      await engine.overrideSession(
        type: OverrideType.confirmationPhrase,
        typedPhrase: 'I deliberately choose to exit focus',
        typedReason: 'Urgent family task',
      );

      expect(engine.currentState, equals(SessionState.overridden));
      expect(bridge.enforcementActive, isFalse);

      // Verify audit trail logged every lifecycle event
      await Future.delayed(const Duration(milliseconds: 50));
      final logs = await auditRepo.getAllLogs();
      expect(logs.any((l) => l.eventType == 'session_start'), isTrue);
      expect(logs.any((l) => l.eventType == 'break_start'), isTrue);
      expect(logs.any((l) => l.eventType == 'break_end'), isTrue);
      expect(logs.any((l) => l.eventType == 'distraction_attempt'), isTrue);
      expect(logs.any((l) => l.eventType == 'override'), isTrue);
    });
  });
}
