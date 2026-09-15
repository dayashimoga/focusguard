import '../domain/models/focus_schedule.dart';

/// Evaluates recurring schedules and computes upcoming trigger events.
class FocusScheduler {
  final List<FocusSchedule> _schedules = [];

  List<FocusSchedule> get schedules => List.unmodifiable(_schedules);

  void setSchedules(List<FocusSchedule> newSchedules) {
    _schedules.clear();
    _schedules.addAll(newSchedules);
  }

  void addSchedule(FocusSchedule schedule) {
    _schedules.add(schedule);
  }

  void removeSchedule(String id) {
    _schedules.removeWhere((s) => s.id == id);
  }

  /// Finds any schedule currently active at the given reference time.
  FocusSchedule? findActiveSchedule(DateTime referenceTime) {
    for (final schedule in _schedules) {
      if (schedule.isActiveAt(referenceTime)) {
        return schedule;
      }
    }
    return null;
  }

  /// Finds the next upcoming schedule event from the given reference time.
  ScheduledEvent? getNextUpcomingSchedule(DateTime referenceTime) {
    ScheduledEvent? nearest;

    for (final schedule in _schedules) {
      if (!schedule.isEnabled) continue;
      final nextStart = schedule.getNextOccurrence(referenceTime);

      if (nearest == null || nextStart.isBefore(nearest.scheduledStartTime)) {
        nearest = ScheduledEvent(
          schedule: schedule,
          scheduledStartTime: nextStart,
        );
      }
    }

    return nearest;
  }
}

/// Represents a scheduled focus event trigger.
class ScheduledEvent {
  final FocusSchedule schedule;
  final DateTime scheduledStartTime;

  const ScheduledEvent({
    required this.schedule,
    required this.scheduledStartTime,
  });

  Duration timeUntil(DateTime now) => scheduledStartTime.difference(now);
}
