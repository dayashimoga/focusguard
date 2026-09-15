/// Monotonic timing utilities that guard against system clock manipulation.
class MonotonicTime {
  static final Stopwatch _internalStopwatch = Stopwatch()..start();
  static final int _initialWallClockMs = DateTime.now().millisecondsSinceEpoch;

  /// Returns milliseconds elapsed on the local monotonic stopwatch since process launch.
  static int get processElapsedMs => _internalStopwatch.elapsedMilliseconds;

  /// Converts milliseconds into HH:MM:SS or MM:SS formatted string.
  static String formatRemainingTime(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Calculates monotonic progress as a fraction between 0.0 and 1.0.
  static double calculateProgress({
    required int totalDurationSeconds,
    required int remainingSeconds,
  }) {
    if (totalDurationSeconds <= 0) return 0.0;
    final elapsed = totalDurationSeconds - remainingSeconds;
    final progress = elapsed / totalDurationSeconds;
    return progress.clamp(0.0, 1.0);
  }

  /// Returns wall clock milliseconds corresponding to the initial baseline.
  static int get initialWallClockMs => _initialWallClockMs;
}
