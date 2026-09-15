import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/domain/models/focus_schedule.dart';
import 'package:focusguard/engine/scheduler.dart';

void main() {
  group('Engine: FocusScheduler', () {
    test('identifies active daytime schedule', () {
      const schedule = FocusSchedule(
        id: 'work_focus',
        profileId: 'preset_deep_work',
        name: 'Work Focus',
        startHour: 9,
        startMinute: 0,
        endHour: 17,
        endMinute: 0,
        daysOfWeek: [1, 2, 3, 4, 5], // Mon-Fri
      );

      // Wednesday at 10:30 AM -> Active
      final wedActive = DateTime(2026, 9, 16, 10, 30); // Wednesday
      expect(schedule.isActiveAt(wedActive), isTrue);

      // Wednesday at 6:00 PM -> Inactive
      final wedEvening = DateTime(2026, 9, 16, 18, 0);
      expect(schedule.isActiveAt(wedEvening), isFalse);

      // Saturday at 11:00 AM -> Inactive (weekend)
      final satMorning = DateTime(2026, 9, 19, 11, 0);
      expect(schedule.isActiveAt(satMorning), isFalse);
    });

    test('handles overnight bedtime schedule spanning midnight', () {
      const bedtime = FocusSchedule(
        id: 'bedtime_sched',
        profileId: 'preset_bedtime',
        name: 'Bedtime',
        startHour: 22,
        startMinute: 0,
        endHour: 7,
        endMinute: 0,
        daysOfWeek: [1, 2, 3, 4, 5], // Mon-Fri nights
      );

      expect(bedtime.isOvernight, isTrue);
      expect(bedtime.durationSeconds, equals(9 * 3600)); // 9 hours

      // Monday night 11:30 PM -> Active
      final monNight = DateTime(2026, 9, 14, 23, 30); // Monday
      expect(bedtime.isActiveAt(monNight), isTrue);

      // Tuesday early morning 5:30 AM -> Active (spanned from Monday night)
      final tueMorning = DateTime(2026, 9, 15, 5, 30); // Tuesday
      expect(bedtime.isActiveAt(tueMorning), isTrue);

      // Tuesday midday 12:00 PM -> Inactive
      final tueNoon = DateTime(2026, 9, 15, 12, 0);
      expect(bedtime.isActiveAt(tueNoon), isFalse);
    });

    test('computes next upcoming scheduled event', () {
      final scheduler = FocusScheduler();

      const morningSchedule = FocusSchedule(
        id: 'morning',
        profileId: 'preset_study',
        name: 'Morning Study',
        startHour: 8,
        startMinute: 0,
        endHour: 10,
        endMinute: 0,
        daysOfWeek: [1, 2, 3, 4, 5],
      );
      scheduler.addSchedule(morningSchedule);

      // Wednesday 7:00 AM -> Next is Wednesday 8:00 AM
      final refTime = DateTime(2026, 9, 16, 7, 0);
      final next = scheduler.getNextUpcomingSchedule(refTime);

      expect(next, isNotNull);
      expect(next!.schedule.id, equals('morning'));
      expect(next.scheduledStartTime.hour, equals(8));
      expect(next.scheduledStartTime.minute, equals(0));
      expect(next.timeUntil(refTime).inHours, equals(1));
    });
  });
}
