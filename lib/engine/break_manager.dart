import 'dart:async';
import '../core/utils/monotonic_time.dart';

/// Event payload emitted during an active break.
class BreakTickEvent {
  final int remainingSeconds;
  final int totalBreakSeconds;
  final double progress;
  final bool isFinished;

  const BreakTickEvent({
    required this.remainingSeconds,
    required this.totalBreakSeconds,
    required this.progress,
    required this.isFinished,
  });
}

/// Coordinates temporary focus pauses and handles automatic resumption upon expiration.
class BreakManager {
  final int Function() getMonotonicNowMs;

  Timer? _breakTimer;
  final StreamController<BreakTickEvent> _breakTickController =
      StreamController<BreakTickEvent>.broadcast();

  int _breakTargetMonotonicMs = 0;
  int _breakDurationSeconds = 0;
  bool _isOnBreak = false;

  BreakManager({int Function()? monotonicTimeProvider})
      : getMonotonicNowMs =
            monotonicTimeProvider ?? (() => MonotonicTime.processElapsedMs);

  Stream<BreakTickEvent> get onBreakTick => _breakTickController.stream;

  bool get isOnBreak => _isOnBreak;
  int get breakDurationSeconds => _breakDurationSeconds;

  /// Starts a temporary break for [durationMinutes] if allowed.
  void startBreak({
    required int durationMinutes,
    required void Function() onBreakExpired,
  }) {
    if (_isOnBreak) return;

    _breakDurationSeconds = durationMinutes * 60;
    final now = getMonotonicNowMs();
    _breakTargetMonotonicMs = now + (_breakDurationSeconds * 1000);
    _isOnBreak = true;

    _emitTick(onBreakExpired);

    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _emitTick(onBreakExpired);
    });
  }

  void _emitTick(void Function() onBreakExpired) {
    final now = getMonotonicNowMs();
    final remainingMs = _breakTargetMonotonicMs - now;
    final remainingSeconds = remainingMs > 0 ? (remainingMs / 1000).ceil() : 0;
    final progress = _breakDurationSeconds > 0
        ? ((_breakDurationSeconds - remainingSeconds) / _breakDurationSeconds)
            .clamp(0.0, 1.0)
        : 1.0;
    final isFinished = remainingSeconds <= 0;

    _breakTickController.add(
      BreakTickEvent(
        remainingSeconds: remainingSeconds,
        totalBreakSeconds: _breakDurationSeconds,
        progress: progress,
        isFinished: isFinished,
      ),
    );

    if (isFinished) {
      endBreak();
      onBreakExpired();
    }
  }

  /// Cancels or ends break early, resuming enforcement immediately.
  void endBreak() {
    _breakTimer?.cancel();
    _breakTimer = null;
    _isOnBreak = false;
    _breakTargetMonotonicMs = 0;
    _breakDurationSeconds = 0;
  }

  void dispose() {
    endBreak();
    _breakTickController.close();
  }
}
