import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/engine/break_manager.dart';

void main() {
  group('Engine: BreakManager', () {
    test('starts temporary break and fires expiration callback upon completion',
        () {
      fakeAsync((async) {
        int simulatedNow = 10000;
        final manager = BreakManager(monotonicTimeProvider: () => simulatedNow);

        final events = <BreakTickEvent>[];
        final sub = manager.onBreakTick.listen(events.add);

        bool expiredFired = false;

        manager.startBreak(
          durationMinutes: 1, // 60 seconds
          onBreakExpired: () {
            expiredFired = true;
          },
        );

        expect(manager.isOnBreak, isTrue);
        expect(manager.breakDurationSeconds, equals(60));

        // Advance 30 seconds
        simulatedNow += 30000;
        async.elapse(const Duration(seconds: 30));

        expect(events.isNotEmpty, isTrue);
        expect(events.last.remainingSeconds, equals(30));
        expect(events.last.progress, closeTo(0.5, 0.05));
        expect(expiredFired, isFalse);

        // Advance remaining 30 seconds
        simulatedNow += 30000;
        async.elapse(const Duration(seconds: 30));

        expect(expiredFired, isTrue);
        expect(manager.isOnBreak, isFalse);

        sub.cancel();
        manager.dispose();
      });
    });

    test('endBreak early clears break state immediately', () {
      final manager = BreakManager();
      manager.startBreak(durationMinutes: 5, onBreakExpired: () {});
      expect(manager.isOnBreak, isTrue);

      manager.endBreak();
      expect(manager.isOnBreak, isFalse);
      expect(manager.breakDurationSeconds, equals(0));
    });
  });
}
