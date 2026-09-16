import 'enums.dart';

/// Immutable domain model representing a Focus Session.
class FocusSession {
  final String id;
  final String profileId;
  final String profileName;
  final RestrictionStrength restrictionStrength;
  final int totalDurationSeconds;
  final int monotonicStartMs;
  final int monotonicTargetMs;
  final int wallClockStartMs;
  final int wallClockTargetMs;
  final SessionState state;
  final int breaksTaken;
  final int maxBreaksAllowed;
  final int distractionAttempts;
  final String? overrideReason;
  final int bootCountAtStart;
  final int gracePeriodSeconds;

  const FocusSession({
    required this.id,
    required this.profileId,
    required this.profileName,
    required this.restrictionStrength,
    required this.totalDurationSeconds,
    required this.monotonicStartMs,
    required this.monotonicTargetMs,
    required this.wallClockStartMs,
    required this.wallClockTargetMs,
    required this.state,
    this.breaksTaken = 0,
    this.maxBreaksAllowed = 2,
    this.distractionAttempts = 0,
    this.overrideReason,
    this.bootCountAtStart = 0,
    this.gracePeriodSeconds = 10,
  });

  /// Calculates monotonic remaining seconds given current monotonic elapsed milliseconds.
  int getRemainingSeconds(int currentMonotonicMs) {
    if (state == SessionState.completed ||
        state == SessionState.overridden ||
        state == SessionState.cancelled ||
        state == SessionState.idle) {
      return 0;
    }
    final remainingMs = monotonicTargetMs - currentMonotonicMs;
    return remainingMs > 0 ? (remainingMs / 1000).ceil() : 0;
  }

  /// Calculates elapsed monotonic seconds.
  int getElapsedSeconds(int currentMonotonicMs) {
    final elapsedMs = currentMonotonicMs - monotonicStartMs;
    final totalMs = monotonicTargetMs - monotonicStartMs;
    if (elapsedMs <= 0) return 0;
    if (elapsedMs >= totalMs) return totalDurationSeconds;
    return (elapsedMs / 1000).floor();
  }

  /// Progress fraction from 0.0 to 1.0.
  double getProgress(int currentMonotonicMs) {
    if (totalDurationSeconds <= 0) return 0.0;
    final remaining = getRemainingSeconds(currentMonotonicMs);
    final progress = (totalDurationSeconds - remaining) / totalDurationSeconds;
    return progress.clamp(0.0, 1.0);
  }

  /// Creates a copy with modified fields.
  FocusSession copyWith({
    String? id,
    String? profileId,
    String? profileName,
    RestrictionStrength? restrictionStrength,
    int? totalDurationSeconds,
    int? monotonicStartMs,
    int? monotonicTargetMs,
    int? wallClockStartMs,
    int? wallClockTargetMs,
    SessionState? state,
    int? breaksTaken,
    int? maxBreaksAllowed,
    int? distractionAttempts,
    String? overrideReason,
    int? bootCountAtStart,
    int? gracePeriodSeconds,
  }) {
    return FocusSession(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      profileName: profileName ?? this.profileName,
      restrictionStrength: restrictionStrength ?? this.restrictionStrength,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      monotonicStartMs: monotonicStartMs ?? this.monotonicStartMs,
      monotonicTargetMs: monotonicTargetMs ?? this.monotonicTargetMs,
      wallClockStartMs: wallClockStartMs ?? this.wallClockStartMs,
      wallClockTargetMs: wallClockTargetMs ?? this.wallClockTargetMs,
      state: state ?? this.state,
      breaksTaken: breaksTaken ?? this.breaksTaken,
      maxBreaksAllowed: maxBreaksAllowed ?? this.maxBreaksAllowed,
      distractionAttempts: distractionAttempts ?? this.distractionAttempts,
      overrideReason: overrideReason ?? this.overrideReason,
      bootCountAtStart: bootCountAtStart ?? this.bootCountAtStart,
      gracePeriodSeconds: gracePeriodSeconds ?? this.gracePeriodSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'profileName': profileName,
      'restrictionStrength': restrictionStrength.name,
      'totalDurationSeconds': totalDurationSeconds,
      'monotonicStartMs': monotonicStartMs,
      'monotonicTargetMs': monotonicTargetMs,
      'wallClockStartMs': wallClockStartMs,
      'wallClockTargetMs': wallClockTargetMs,
      'state': state.name,
      'breaksTaken': breaksTaken,
      'maxBreaksAllowed': maxBreaksAllowed,
      'distractionAttempts': distractionAttempts,
      'overrideReason': overrideReason,
      'bootCountAtStart': bootCountAtStart,
      'gracePeriodSeconds': gracePeriodSeconds,
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: (map['id'] as String?) ?? 'corrupted_session',
      profileId: (map['profileId'] as String?) ?? 'corrupted_profile',
      profileName: (map['profileName'] as String?) ?? 'Restored Session',
      restrictionStrength: RestrictionStrength.values.firstWhere(
        (e) => e.name == map['restrictionStrength'],
        orElse: () => RestrictionStrength.focus,
      ),
      totalDurationSeconds: (map['totalDurationSeconds'] as num?)?.toInt() ?? 0,
      monotonicStartMs: (map['monotonicStartMs'] as num?)?.toInt() ?? 0,
      monotonicTargetMs: (map['monotonicTargetMs'] as num?)?.toInt() ?? 0,
      wallClockStartMs: (map['wallClockStartMs'] as num?)?.toInt() ?? 0,
      wallClockTargetMs: (map['wallClockTargetMs'] as num?)?.toInt() ?? 0,
      state: SessionState.values.firstWhere(
        (e) => e.name == map['state'],
        orElse: () => SessionState.idle,
      ),
      breaksTaken: (map['breaksTaken'] as num?)?.toInt() ?? 0,
      maxBreaksAllowed: (map['maxBreaksAllowed'] as num?)?.toInt() ?? 2,
      distractionAttempts: (map['distractionAttempts'] as num?)?.toInt() ?? 0,
      overrideReason: map['overrideReason'] as String?,
      bootCountAtStart: (map['bootCountAtStart'] as num?)?.toInt() ?? 0,
      gracePeriodSeconds: (map['gracePeriodSeconds'] as num?)?.toInt() ?? 10,
    );
  }
}
