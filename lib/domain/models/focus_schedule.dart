/// Recurring schedule for automated focus sessions with DST and timezone resilience.
class FocusSchedule {
  final String id;
  final String profileId;
  final String name;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final List<int> daysOfWeek; // 1 = Mon ... 7 = Sun (DateTime standard)
  final String timezoneId;
  final bool isEnabled;

  const FocusSchedule({
    required this.id,
    required this.profileId,
    required this.name,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.daysOfWeek,
    this.timezoneId = 'UTC',
    this.isEnabled = true,
  });

  /// Calculates the next scheduled start DateTime based on reference time.
  DateTime getNextOccurrence(DateTime referenceTime) {
    for (int dayOffset = 0; dayOffset < 8; dayOffset++) {
      final candidateDate = referenceTime.add(Duration(days: dayOffset));
      final candidateWeekday = candidateDate.weekday;

      if (daysOfWeek.contains(candidateWeekday)) {
        final candidateStart = DateTime(
          candidateDate.year,
          candidateDate.month,
          candidateDate.day,
          startHour,
          startMinute,
        );

        if (candidateStart.isAfter(referenceTime)) {
          return candidateStart;
        }
      }
    }

    // Fallback if none found within 7 days
    return referenceTime.add(const Duration(days: 1));
  }

  /// Checks if a given timestamp falls within an active scheduled window.
  bool isActiveAt(DateTime time) {
    if (!isEnabled) return false;

    final currentMinutes = time.hour * 60 + time.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    if (!isOvernight) {
      // Standard same-day window (e.g. 08:00 to 17:00)
      if (!daysOfWeek.contains(time.weekday)) return false;
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // Overnight window (e.g. 22:00 to 07:00 next day)
      // 1. Evening portion of a session started today
      if (daysOfWeek.contains(time.weekday) && currentMinutes >= startMinutes) {
        return true;
      }
      // 2. Morning portion of a session started yesterday
      final prevDay = time.weekday == 1 ? 7 : time.weekday - 1;
      if (daysOfWeek.contains(prevDay) && currentMinutes < endMinutes) {
        return true;
      }
      return false;
    }
  }

  /// Whether the schedule spans midnight into the next day (e.g. 22:00 to 07:00).
  bool get isOvernight {
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;
    return endMinutes <= startMinutes;
  }

  /// Total duration of one session window in seconds.
  int get durationSeconds {
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    if (!isOvernight) {
      return (endMinutes - startMinutes) * 60;
    } else {
      return ((24 * 60 - startMinutes) + endMinutes) * 60;
    }
  }

  FocusSchedule copyWith({
    String? id,
    String? profileId,
    String? name,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    List<int>? daysOfWeek,
    String? timezoneId,
    bool? isEnabled,
  }) {
    return FocusSchedule(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      timezoneId: timezoneId ?? this.timezoneId,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'name': name,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'daysOfWeek': daysOfWeek.join(','),
      'timezoneId': timezoneId,
      'isEnabled': isEnabled ? 1 : 0,
    };
  }

  factory FocusSchedule.fromMap(Map<String, dynamic> map) {
    final daysStr = map['daysOfWeek'] as String? ?? '';
    return FocusSchedule(
      id: map['id'] as String,
      profileId: map['profileId'] as String,
      name: map['name'] as String,
      startHour: (map['startHour'] as num).toInt(),
      startMinute: (map['startMinute'] as num).toInt(),
      endHour: (map['endHour'] as num).toInt(),
      endMinute: (map['endMinute'] as num).toInt(),
      daysOfWeek: daysStr.isEmpty
          ? [1, 2, 3, 4, 5]
          : daysStr.split(',').map((s) => int.parse(s.trim())).toList(),
      timezoneId: map['timezoneId'] as String? ?? 'UTC',
      isEnabled: (map['isEnabled'] as int? ?? 1) == 1,
    );
  }
}
