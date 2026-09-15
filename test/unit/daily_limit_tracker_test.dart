import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/domain/models/daily_limit.dart';
import 'package:focusguard/engine/daily_limit_tracker.dart';

void main() {
  group('Engine: DailyLimitTracker', () {
    test('updates app usage and emits warning and limit reached events',
        () async {
      final tracker = DailyLimitTracker();

      const limit = DailyLimit(
        id: 'limit_insta',
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        limitMinutes: 60,
        usedMinutes: 0,
      );

      tracker.setLimits([limit]);

      final alertEvents = <DailyLimitAlertEvent>[];
      final sub = tracker.onLimitAlert.listen(alertEvents.add);

      // Usage at 30 min (50%) -> no alert
      tracker.updateUsage('com.instagram.android', 30);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(alertEvents.isEmpty, isTrue);

      // Usage at 50 min (83% >= 80%) -> warning alert
      tracker.updateUsage('com.instagram.android', 50);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(alertEvents.length, equals(1));
      expect(alertEvents.last.isWarning, isTrue);
      expect(alertEvents.last.isExhausted, isFalse);

      // Usage at 60 min (100%) -> exhausted alert
      tracker.updateUsage('com.instagram.android', 60);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(alertEvents.length, equals(2));
      expect(alertEvents.last.isExhausted, isTrue);

      final current = tracker.getLimitForPackage('com.instagram.android');
      expect(current!.isExhausted, isTrue);
      expect(current.remainingMinutes, equals(0));

      // Reset
      tracker.resetDailyUsage();
      final resetLimit = tracker.getLimitForPackage('com.instagram.android');
      expect(resetLimit!.usedMinutes, equals(0));
      expect(resetLimit.isExhausted, isFalse);

      await sub.cancel();
      tracker.dispose();
    });
  });
}
