import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/domain/models/app_info.dart';
import 'package:focusguard/domain/models/audit_entry.dart';
import 'package:focusguard/domain/models/capability_matrix_entry.dart';
import 'package:focusguard/domain/models/daily_limit.dart';
import 'package:focusguard/domain/models/enums.dart';
import 'package:focusguard/domain/models/focus_profile.dart';
import 'package:focusguard/domain/models/focus_schedule.dart';
import 'package:focusguard/domain/models/focus_session.dart';
import 'package:focusguard/domain/models/override_policy.dart';

void main() {
  group('Domain Models: Comprehensive Serialization & Methods', () {
    test('AppInfo serialization, equality, and limit check', () {
      const app = AppInfo(
        packageName: 'com.android.dialer',
        appName: 'Phone',
        category: AppCategory.communication,
        isEssential: true,
        usageTodaySeconds: 300,
        dailyLimitSeconds: 600,
      );

      expect(app.hasLimit, isTrue);
      expect(app.isLimitExhausted, isFalse);
      expect(app.limitProgress, closeTo(0.5, 0.01));

      final map = app.toMap();
      final fromMap = AppInfo.fromMap(map);
      expect(fromMap.packageName, equals(app.packageName));
      expect(fromMap.appName, equals(app.appName));
      expect(fromMap.category, equals(AppCategory.communication));
      expect(fromMap.isEssential, isTrue);
      expect(fromMap.dailyLimitSeconds, equals(600));

      final updated = app.copyWith(
        appName: 'Emergency Dialer',
        isEssential: false,
        category: AppCategory.social,
      );
      expect(updated.appName, equals('Emergency Dialer'));
      expect(updated.isEssential, isFalse);
      expect(updated.category, equals(AppCategory.social));
    });

    test('OverridePolicy methods and serialization', () {
      const policy = OverridePolicy(
        enabledOverrideTypes: [
          OverrideType.immediate,
          OverrideType.delayedCooldown,
          OverrideType.confirmationPhrase,
          OverrideType.pinProtected,
        ],
        cooldownSeconds: 45,
        confirmationPhrase: 'I consciously exit focus now',
        isPinRequired: true,
        requireReason: true,
        maxOverridesPerDay: 5,
        usedOverridesToday: 2,
      );

      expect(policy.isQuotaExhausted, isFalse);
      expect(policy.remainingOverridesToday, equals(3));

      final exhaustedPolicy = policy.copyWith(usedOverridesToday: 5);
      expect(exhaustedPolicy.isQuotaExhausted, isTrue);
      expect(exhaustedPolicy.remainingOverridesToday, equals(0));

      final map = policy.toMap();
      final restored = OverridePolicy.fromMap(map);
      expect(restored.cooldownSeconds, equals(45));
      expect(
          restored.confirmationPhrase, equals('I consciously exit focus now'));
      expect(restored.isPinRequired, isTrue);
      expect(restored.requireReason, isTrue);
      expect(restored.maxOverridesPerDay, equals(5));
      expect(restored.usedOverridesToday, equals(2));
      expect(
          restored.enabledOverrideTypes, contains(OverrideType.pinProtected));
    });

    test('CapabilityMatrixEntry serialization', () {
      const entry = CapabilityMatrixEntry(
        feature: 'Foreground App Detection',
        androidSupport: 'UsageStatsManager / Accessibility',
        iosSupport: 'DeviceActivity / Screen Time',
        requirement: 'UsageStats permission',
        enforcementLevel: 'System Service',
        verified: VerificationClassification.VERIFIED,
        notes: 'Fully verified on Android 14',
      );

      final map = entry.toMap();
      final restored = CapabilityMatrixEntry.fromMap(map);
      expect(restored.feature, equals(entry.feature));
      expect(restored.androidSupport, equals(entry.androidSupport));
      expect(restored.iosSupport, equals(entry.iosSupport));
      expect(restored.requirement, equals(entry.requirement));
      expect(restored.enforcementLevel, equals(entry.enforcementLevel));
      expect(restored.verified, equals(VerificationClassification.VERIFIED));
      expect(restored.notes, equals(entry.notes));
    });

    test('DailyLimit calculations, serialization, and status checks', () {
      const limit = DailyLimit(
        id: 'dl_insta',
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        limitMinutes: 60,
        usedMinutes: 45,
        isDeviceWide: false,
        isEnabled: true,
      );

      expect(limit.isExhausted, isFalse);
      expect(limit.remainingMinutes, equals(15));
      expect(limit.progressFraction, closeTo(0.75, 0.01));

      final exhaustedLimit = limit.copyWith(usedMinutes: 65);
      expect(exhaustedLimit.isExhausted, isTrue);
      expect(exhaustedLimit.remainingMinutes, equals(0));
      expect(exhaustedLimit.progressFraction, equals(1.0));

      final map = limit.toMap();
      final restored = DailyLimit.fromMap(map);
      expect(restored.id, equals(limit.id));
      expect(restored.packageName, equals('com.instagram.android'));
      expect(restored.appName, equals('Instagram'));
      expect(restored.limitMinutes, equals(60));
      expect(restored.usedMinutes, equals(45));
      expect(restored.isDeviceWide, isFalse);
      expect(restored.isEnabled, isTrue);
    });

    test('FocusProfile presets, serialization, and copyWith', () {
      final presets = FocusProfile.defaultPresets;
      expect(presets.length, greaterThanOrEqualTo(4));

      final deepWork = presets.firstWhere((p) => p.id == 'preset_deep_work');
      expect(
          deepWork.restrictionStrength, equals(RestrictionStrength.deepFocus));
      expect(deepWork.isPreset, isTrue);

      const custom = FocusProfile(
        id: 'profile_custom_1',
        name: 'Weekend Unplug',
        description: 'Unplug from work tools',
        iconName: 'weekend',
        restrictionStrength: RestrictionStrength.strict,
        blockedPackageNames: ['com.slack.work', 'com.google.android.gm'],
        allowedPackageNames: ['com.spotify.music'],
        blockedCategories: [AppCategory.productivity],
        isPreset: false,
      );

      final map = custom.toMap();
      final restored = FocusProfile.fromMap(map);
      expect(restored.id, equals('profile_custom_1'));
      expect(restored.name, equals('Weekend Unplug'));
      expect(restored.description, equals('Unplug from work tools'));
      expect(restored.blockedPackageNames, contains('com.slack.work'));
      expect(restored.allowedPackageNames, contains('com.spotify.music'));
      expect(restored.blockedCategories, contains(AppCategory.productivity));
      expect(restored.isPreset, isFalse);

      final modified = custom.copyWith(
        name: 'Renamed Profile',
        isPreset: true,
      );
      expect(modified.name, equals('Renamed Profile'));
      expect(modified.isPreset, isTrue);
    });

    test('FocusSchedule serialization, getNextOccurrence, and copyWith', () {
      const schedule = FocusSchedule(
        id: 'sched_work',
        profileId: 'preset_deep_work',
        name: 'Work Hours',
        startHour: 9,
        startMinute: 0,
        endHour: 17,
        endMinute: 30,
        daysOfWeek: [1, 2, 3, 4, 5],
        timezoneId: 'UTC',
        isEnabled: true,
      );

      expect(schedule.isOvernight, isFalse);
      expect(schedule.durationSeconds, equals(8 * 3600 + 30 * 60));

      final map = schedule.toMap();
      final restored = FocusSchedule.fromMap(map);
      expect(restored.id, equals('sched_work'));
      expect(restored.name, equals('Work Hours'));
      expect(restored.daysOfWeek, equals([1, 2, 3, 4, 5]));
      expect(restored.startHour, equals(9));
      expect(restored.endMinute, equals(30));

      // Next occurrence from a Sunday
      final sundayMorning = DateTime(2026, 9, 13, 8, 0); // Sunday
      final nextOccur = schedule.getNextOccurrence(sundayMorning);
      expect(nextOccur.weekday, equals(1)); // Monday
      expect(nextOccur.hour, equals(9));
      expect(nextOccur.minute, equals(0));

      final disabledSchedule = schedule.copyWith(isEnabled: false);
      expect(disabledSchedule.isEnabled, isFalse);
      expect(
          disabledSchedule.isActiveAt(DateTime(2026, 9, 14, 10, 0)), isFalse);
    });

    test('FocusSession progress, elapsed, serialization, and copyWith', () {
      const session = FocusSession(
        id: 'sess_100',
        profileId: 'preset_deep_work',
        profileName: 'Deep Work',
        restrictionStrength: RestrictionStrength.deepFocus,
        totalDurationSeconds: 3600,
        monotonicStartMs: 10000,
        monotonicTargetMs: 10000 + (3600 * 1000),
        wallClockStartMs: 1700000000000,
        wallClockTargetMs: 1700000000000 + (3600 * 1000),
        state: SessionState.active,
        distractionAttempts: 3,
        breaksTaken: 1,
        bootCountAtStart: 1,
      );

      expect(session.getElapsedSeconds(10000 + (1800 * 1000)), equals(1800));
      expect(session.getRemainingSeconds(10000 + (1800 * 1000)), equals(1800));
      expect(session.getProgress(10000 + (1800 * 1000)), closeTo(0.5, 0.01));

      final map = session.toMap();
      final restored = FocusSession.fromMap(map);
      expect(restored.id, equals('sess_100'));
      expect(restored.profileName, equals('Deep Work'));
      expect(restored.state, equals(SessionState.active));
      expect(restored.distractionAttempts, equals(3));
      expect(restored.breaksTaken, equals(1));

      final modified = session.copyWith(
        distractionAttempts: 7,
        state: SessionState.completed,
      );
      expect(modified.distractionAttempts, equals(7));
      expect(modified.state, equals(SessionState.completed));
      expect(modified.getRemainingSeconds(10000 + (1800 * 1000)), equals(0));
    });

    test('AuditEntry serialization and formatting', () {
      const entry = AuditEntry(
        id: 'audit_1',
        timestampMs: 1700000000000,
        eventType: 'emergency_override',
        description: 'User invoked emergency override',
        sessionId: 'sess_100',
      );

      expect(entry.timestamp,
          equals(DateTime.fromMillisecondsSinceEpoch(1700000000000)));

      final map = entry.toMap();
      final restored = AuditEntry.fromMap(map);
      expect(restored.id, equals('audit_1'));
      expect(restored.eventType, equals('emergency_override'));
      expect(restored.description, equals('User invoked emergency override'));
      expect(restored.sessionId, equals('sess_100'));
    });
  });
}
