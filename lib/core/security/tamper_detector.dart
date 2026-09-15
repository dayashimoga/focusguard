/// Anomaly and tampering detection engine.
/// Identifies wall-clock tampering, sudden time jumps, and unauthorized session termination attempts.
class TamperDetector {
  // Threshold in milliseconds beyond which a wall-clock delta discrepancy is flagged as tampering
  static const int clockSkewThresholdMs = 15000; // 15 seconds

  /// Inspects timing deltas to identify whether the system wall clock was manipulated.
  ///
  /// [lastMonotonicMs] - previous recorded monotonic timestamp
  /// [currentMonotonicMs] - current monotonic timestamp
  /// [lastWallClockMs] - previous recorded wall-clock timestamp
  /// [currentWallClockMs] - current wall-clock timestamp
  static TamperCheckResult checkClockIntegrity({
    required int lastMonotonicMs,
    required int currentMonotonicMs,
    required int lastWallClockMs,
    required int currentWallClockMs,
  }) {
    final monotonicDelta = currentMonotonicMs - lastMonotonicMs;
    final wallClockDelta = currentWallClockMs - lastWallClockMs;

    // Monotonic clock can never step backward on real hardware
    if (monotonicDelta < 0) {
      return TamperCheckResult(
        tampered: true,
        reason: 'Monotonic clock stepped backward by ${-monotonicDelta}ms',
        skewMs: monotonicDelta,
      );
    }

    final discrepancy = (wallClockDelta - monotonicDelta).abs();

    if (discrepancy > clockSkewThresholdMs) {
      final direction =
          wallClockDelta > monotonicDelta ? 'forward' : 'backward';
      return TamperCheckResult(
        tampered: true,
        reason:
            'Wall clock shifted $direction by ${discrepancy}ms relative to monotonic clock',
        skewMs: discrepancy,
      );
    }

    return const TamperCheckResult(
      tampered: false,
      reason: 'Clock integrity normal',
      skewMs: 0,
    );
  }

  /// Verifies if device was rebooted during an active session.
  static bool wasDeviceRebooted({
    required int sessionStartBootCount,
    required int currentBootCount,
  }) {
    return currentBootCount > sessionStartBootCount;
  }
}

/// Result of clock integrity verification.
class TamperCheckResult {
  final bool tampered;
  final String reason;
  final int skewMs;

  const TamperCheckResult({
    required this.tampered,
    required this.reason,
    required this.skewMs,
  });

  @override
  String toString() =>
      'TamperCheckResult(tampered: $tampered, reason: $reason, skewMs: $skewMs)';
}
