import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/presentation/widgets/circular_timer_ring.dart';

void main() {
  group('Widget: CircularTimerRing', () {
    testWidgets('renders remaining formatted time and subtitle correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CircularTimerRing(
              totalDurationSeconds: 3600,
              remainingSeconds: 1800,
              subtitle: 'Halfway there',
            ),
          ),
        ),
      );

      // 1800s is 30:00
      expect(find.text('30:00'), findsOneWidget);
      expect(find.text('Halfway there'), findsOneWidget);
    });

    testWidgets('formats hours when remaining duration exceeds 60 minutes',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CircularTimerRing(
              totalDurationSeconds: 7200,
              remainingSeconds: 5400, // 1h 30m
            ),
          ),
        ),
      );

      expect(find.text('01:30:00'), findsOneWidget);
      expect(find.text('25% completed'), findsOneWidget);
    });
  });
}
