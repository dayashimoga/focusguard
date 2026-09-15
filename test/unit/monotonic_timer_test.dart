import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/engine/monotonic_timer.dart';

void main() {
  group('Engine: MonotonicCountdownTimer', () {
    test('emits periodic ticks with accurate remaining seconds and progress',
        () {
      fakeAsync((async) {
        int simulatedMonotonicMs = 10000;

        final timer = MonotonicCountdownTimer(
          totalDurationSeconds: 10,
          monotonicTargetMs: 20000,
          wallClockTargetMs: DateTime.now().millisecondsSinceEpoch + 10000,
          monotonicTimeProvider: () => simulatedMonotonicMs,
        );

        final tickEvents = <TimerTickEvent>[];
        final sub = timer.onTick.listen(tickEvents.add);

        timer.start();
        expect(timer.isRunning, isTrue);

        // Advance 3 seconds
        simulatedMonotonicMs += 3000;
        async.elapse(const Duration(seconds: 3));

        expect(tickEvents.length, greaterThanOrEqualTo(3));
        final lastTick = tickEvents.last;
        expect(lastTick.remainingSeconds, equals(7));
        expect(lastTick.elapsedSeconds, equals(3));
        expect(lastTick.progress, closeTo(0.3, 0.05));
        expect(lastTick.isFinished, isFalse);

        // Advance remaining 7 seconds
        simulatedMonotonicMs += 7000;
        async.elapse(const Duration(seconds: 7));

        expect(timer.isRunning, isFalse);
        final finalTick = tickEvents.last;
        expect(finalTick.remainingSeconds, equals(0));
        expect(finalTick.progress, equals(1.0));
        expect(finalTick.isFinished, isTrue);

        sub.cancel();
        timer.dispose();
      });
    });

    test('currentRemainingSeconds computes correct delta directly', () {
      int simulatedNow = 50000;
      final timer = MonotonicCountdownTimer(
        totalDurationSeconds: 30,
        monotonicTargetMs: 80000,
        wallClockTargetMs: 1700000000000,
        monotonicTimeProvider: () => simulatedNow,
      );

      expect(timer.currentRemainingSeconds, equals(30));

      simulatedNow += 15000;
      expect(timer.currentRemainingSeconds, equals(15));

      simulatedNow += 20000; // Past target
      expect(timer.currentRemainingSeconds, equals(0));
    });
  });
}
