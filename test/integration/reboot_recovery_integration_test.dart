import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/domain/models/app_info.dart';
import 'package:focusguard/domain/models/enums.dart';
import 'package:focusguard/domain/models/focus_session.dart';
import 'package:focusguard/engine/focus_engine.dart';
import 'package:focusguard/persistence/database_helper.dart';
import 'package:focusguard/persistence/session_repository.dart';
import 'package:focusguard/platform/platform_bridge.dart';

class RebootPlatformBridge implements PlatformBridge {
  bool enforcementActive = false;

  @override
  Future<Map<String, dynamic>> getCapabilities() async =>
      {'hasMonotonicClock': true};

  @override
  Future<int> getMonotonicElapsedRealtime() async => 20000;

  @override
  Future<int> getBootCount() async => 2; // Incremented boot count

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
  late RebootPlatformBridge bridge;

  setUp(() async {
    db = DatabaseHelper.instance;
    await db.clearAllData();
    sessionRepo = SessionRepository(databaseHelper: db);
    bridge = RebootPlatformBridge();
  });

  group('Integration: Reboot & Crash Recovery', () {
    test('restores ongoing session if target wall clock has not yet passed',
        () async {
      // 1. Session active before device shut down
      const remainingMillis = 1200 * 1000; // 20 minutes left
      final targetWallClock =
          DateTime.now().millisecondsSinceEpoch + remainingMillis;

      final preShutdownSession = FocusSession(
        id: 'reboot_sess_1',
        profileId: 'preset_deep_work',
        profileName: 'Deep Work',
        restrictionStrength: RestrictionStrength.deepFocus,
        totalDurationSeconds: 1800,
        monotonicStartMs: 5000,
        monotonicTargetMs: 5000 + remainingMillis,
        wallClockStartMs: 1700000000000,
        wallClockTargetMs: targetWallClock,
        state: SessionState.active,
        bootCountAtStart: 1,
      );

      await sessionRepo.saveSession(preShutdownSession);

      // 2. Device boots up; new FocusEngine initialized
      final restoredEngine = FocusEngine(
        platformBridge: bridge,
        monotonicTimeProvider: () => 1000, // new boot monotonic baseline
      );

      final active = await sessionRepo.getActiveSession();
      expect(active, isNotNull);

      // 3. Engine recovers the active session
      final didRestore =
          await restoredEngine.restoreInterruptedSession(active!);
      expect(didRestore, isTrue);
      expect(restoredEngine.currentState, equals(SessionState.active));
      expect(bridge.enforcementActive, isTrue);
      expect(
          restoredEngine.currentSession!.monotonicTargetMs, greaterThan(1000));

      restoredEngine.dispose();
    });

    test('marks session as completed if device was off past the target time',
        () async {
      // Session target was 10 minutes ago
      final pastTargetWallClock =
          DateTime.now().millisecondsSinceEpoch - (600 * 1000);

      final expiredSession = FocusSession(
        id: 'expired_sess',
        profileId: 'preset_deep_work',
        profileName: 'Deep Work',
        restrictionStrength: RestrictionStrength.deepFocus,
        totalDurationSeconds: 1800,
        monotonicStartMs: 5000,
        monotonicTargetMs: 5000 + (1800 * 1000),
        wallClockStartMs: 1700000000000,
        wallClockTargetMs: pastTargetWallClock,
        state: SessionState.active,
      );

      final restoredEngine = FocusEngine(
        platformBridge: bridge,
        monotonicTimeProvider: () => 1000,
      );

      final didRestore =
          await restoredEngine.restoreInterruptedSession(expiredSession);
      expect(didRestore, isFalse);
      expect(restoredEngine.currentState, equals(SessionState.completed));
      expect(bridge.enforcementActive, isFalse);

      restoredEngine.dispose();
    });
  });
}
