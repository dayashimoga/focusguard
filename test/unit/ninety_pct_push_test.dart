import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/core/utils/logger.dart';
import 'package:focusguard/core/utils/monotonic_time.dart';
import 'package:focusguard/domain/models/app_info.dart';
import 'package:focusguard/domain/models/focus_profile.dart';
import 'package:focusguard/engine/focus_engine.dart';
import 'package:focusguard/persistence/database_helper.dart';
import 'package:focusguard/platform/platform_bridge.dart';
import 'package:focusguard/presentation/screens/help_emergency_screen.dart';

class PushMockBridge extends Fake implements PlatformBridge {
  @override
  Future<Map<String, dynamic>> getCapabilities() async => {'platform': 'mock'};
  @override
  Future<int> getMonotonicElapsedRealtime() async => 50000;
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
  }) async =>
      true;
  @override
  Future<bool> stopEnforcement() async => true;
  @override
  Future<List<AppInfo>> getInstalledApps() async => [];
}

void main() {
  test('AppLogger and MonotonicTime remaining branches', () {
    AppLogger.debug('Debug sample with email user@test.com and pin 9999');
    AppLogger.error(
      'Sample error with stack trace',
      error: Exception('Test Error Object'),
      stackTrace: StackTrace.current,
    );

    expect(MonotonicTime.processElapsedMs, greaterThanOrEqualTo(0));
    expect(MonotonicTime.initialWallClockMs, greaterThan(0));
    expect(MonotonicTime.formatRemainingTime(0), equals('00:00'));
    expect(MonotonicTime.formatRemainingTime(-5), equals('00:00'));
    expect(MonotonicTime.formatRemainingTime(65), equals('01:05'));
    expect(MonotonicTime.formatRemainingTime(3665), equals('01:01:05'));
    expect(
        MonotonicTime.calculateProgress(
            totalDurationSeconds: 0, remainingSeconds: 0),
        equals(0.0));
    expect(
        MonotonicTime.calculateProgress(
            totalDurationSeconds: 100, remainingSeconds: 25),
        equals(0.75));
  });

  test('DatabaseHelper delete and clear operations', () async {
    final db = DatabaseHelper.instance;

    await db.insertProfile({
      'id': 'temp_prof',
      'name': 'Temp',
      'description': 'Temporary profile',
      'iconName': 'temp',
      'restrictionStrength': 'focus',
      'isPreset': 0,
      'isDefault': 0,
    });
    expect(
        (await db.getAllProfiles()).any((p) => p['id'] == 'temp_prof'), isTrue);

    await db.deleteProfile('temp_prof');
    expect((await db.getAllProfiles()).any((p) => p['id'] == 'temp_prof'),
        isFalse);

    await db.insertSchedule({
      'id': 'temp_sched',
      'profileId': 'temp_prof',
      'name': 'Temp Schedule',
      'startHour': 10,
      'startMinute': 0,
      'endHour': 11,
      'endMinute': 0,
      'daysOfWeek': '1,2',
      'timezoneId': 'UTC',
      'isEnabled': 1,
    });
    expect((await db.getAllSchedules()).any((s) => s['id'] == 'temp_sched'),
        isTrue);

    await db.deleteSchedule('temp_sched');
    expect((await db.getAllSchedules()).any((s) => s['id'] == 'temp_sched'),
        isFalse);

    await db.insertDailyLimit({
      'id': 'temp_limit',
      'packageName': 'com.temp.app',
      'appName': 'Temp App',
      'limitMinutes': 60,
    });
    expect((await db.getAllDailyLimits()).any((l) => l['id'] == 'temp_limit'),
        isTrue);

    await db.clearAllData();
    expect(await db.getAllSessions(), isEmpty);
  });

  testWidgets('HelpEmergencyScreen emergency dialer tap', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final bridge = PushMockBridge();
    final engine = FocusEngine(
      platformBridge: bridge,
      monotonicTimeProvider: () => 100000,
    );

    await engine.startSession(
      profile: FocusProfile.defaultPresets.first,
      durationMinutes: 30,
      gracePeriodSeconds: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HelpEmergencyScreen(focusEngine: engine),
      ),
    );
    await tester.pumpAndSettle();

    final dialerBtn = find.text('Open Emergency Dialer & Unlock');
    expect(dialerBtn, findsOneWidget);
    await tester.tap(dialerBtn);
    await tester.pumpAndSettle();

    engine.dispose();
  });
}
