import 'dart:async';
import '../core/security/tamper_detector.dart';
import '../core/utils/monotonic_time.dart';

/// Event payload emitted on each monotonic timer tick.
class TimerTickEvent {
  final int remainingSeconds;
  final int elapsedSeconds;
  final double progress;
  final bool isFinished;
  final TamperCheckResult? tamperAlert;

  const TimerTickEvent({
    required this.remainingSeconds,
    required this.elapsedSeconds,
    required this.progress,
    required this.isFinished,
    this.tamperAlert,
  });
}

/// Periodic monotonic countdown timer resilient to process pauses, UI freezes, and wall-clock manipulation.
class MonotonicCountdownTimer {
  final int totalDurationSeconds;
  final int monotonicTargetMs;
  final int wallClockTargetMs;
  final int Function() getMonotonicNowMs;

  Timer? _ticker;
  final StreamController<TimerTickEvent> _tickController =
      StreamController<TimerTickEvent>.broadcast();

  int _lastMonotonicMs = 0;
  int _lastWallClockMs = 0;
  bool _isRunning = false;

  MonotonicCountdownTimer({
    required this.totalDurationSeconds,
    required this.monotonicTargetMs,
    required this.wallClockTargetMs,
    int Function()? monotonicTimeProvider,
  }) : getMonotonicNowMs =
            monotonicTimeProvider ?? (() => MonotonicTime.processElapsedMs);

  Stream<TimerTickEvent> get onTick => _tickController.stream;

  bool get isRunning => _isRunning;

  /// Starts the 1-second interval ticker.
  void start() {
    if (_isRunning) return;
    _isRunning = true;

    _lastMonotonicMs = getMonotonicNowMs();
    _lastWallClockMs = DateTime.now().millisecondsSinceEpoch;

    // Immediately emit first tick
    _emitTick();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _emitTick();
    });
  }

  void _emitTick() {
    final currentMonotonic = getMonotonicNowMs();
    final currentWallClock = DateTime.now().millisecondsSinceEpoch;

    // Check for system clock tampering
    TamperCheckResult? tamperAlert;
    if (_lastMonotonicMs > 0 && _lastWallClockMs > 0) {
      final check = TamperDetector.checkClockIntegrity(
        lastMonotonicMs: _lastMonotonicMs,
        currentMonotonicMs: currentMonotonic,
        lastWallClockMs: _lastWallClockMs,
        currentWallClockMs: currentWallClock,
      );
      if (check.tampered) {
        tamperAlert = check;
      }
    }

    _lastMonotonicMs = currentMonotonic;
    _lastWallClockMs = currentWallClock;

    final diffMs = monotonicTargetMs - currentMonotonic;
    final remainingSeconds = diffMs > 0 ? (diffMs / 1000).ceil() : 0;
    final elapsedSeconds = (totalDurationSeconds - remainingSeconds)
        .clamp(0, totalDurationSeconds);
    final progress = totalDurationSeconds > 0
        ? (elapsedSeconds / totalDurationSeconds).clamp(0.0, 1.0)
        : 1.0;
    final isFinished = remainingSeconds <= 0;

    _tickController.add(
      TimerTickEvent(
        remainingSeconds: remainingSeconds,
        elapsedSeconds: elapsedSeconds,
        progress: progress,
        isFinished: isFinished,
        tamperAlert: tamperAlert,
      ),
    );

    if (isFinished) {
      stop();
    }
  }

  /// Calculates current remaining seconds directly from monotonic time.
  int get currentRemainingSeconds {
    final now = getMonotonicNowMs();
    final diff = monotonicTargetMs - now;
    return diff > 0 ? (diff / 1000).ceil() : 0;
  }

  void stop() {
    _ticker?.cancel();
    _ticker = null;
    _isRunning = false;
  }

  void dispose() {
    stop();
    _tickController.close();
  }
}
