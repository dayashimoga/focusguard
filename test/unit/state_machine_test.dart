import 'package:flutter_test/flutter_test.dart';
import 'package:focusguard/domain/models/enums.dart';
import 'package:focusguard/domain/state_machine/session_state_machine.dart';

void main() {
  group('Domain: SessionStateMachine', () {
    test('initializes to idle state by default', () {
      final sm = SessionStateMachine();
      expect(sm.currentState, equals(SessionState.idle));
    });

    test(
        'validates valid forward transition sequence: idle -> gracePeriod -> active -> onBreak -> active -> completed',
        () {
      final sm = SessionStateMachine();

      expect(sm.canTransitionTo(SessionState.gracePeriod), isTrue);
      sm.transitionTo(SessionState.gracePeriod);
      expect(sm.currentState, equals(SessionState.gracePeriod));

      expect(sm.canTransitionTo(SessionState.active), isTrue);
      sm.transitionTo(SessionState.active);
      expect(sm.currentState, equals(SessionState.active));

      expect(sm.canTransitionTo(SessionState.onBreak), isTrue);
      sm.transitionTo(SessionState.onBreak);
      expect(sm.currentState, equals(SessionState.onBreak));

      expect(sm.canTransitionTo(SessionState.active), isTrue);
      sm.transitionTo(SessionState.active);
      expect(sm.currentState, equals(SessionState.active));

      expect(sm.canTransitionTo(SessionState.completed), isTrue);
      sm.transitionTo(SessionState.completed);
      expect(sm.currentState, equals(SessionState.completed));
    });

    test('supports gracePeriod cancellation', () {
      final sm = SessionStateMachine();
      sm.transitionTo(SessionState.gracePeriod);

      expect(sm.canTransitionTo(SessionState.cancelled), isTrue);
      sm.transitionTo(SessionState.cancelled);
      expect(sm.currentState, equals(SessionState.cancelled));

      // Reset
      sm.reset();
      expect(sm.currentState, equals(SessionState.idle));
    });

    test('supports session override from active and onBreak states', () {
      final sm1 = SessionStateMachine();
      sm1.transitionTo(SessionState.active);
      expect(sm1.canTransitionTo(SessionState.overridden), isTrue);
      sm1.transitionTo(SessionState.overridden);
      expect(sm1.currentState, equals(SessionState.overridden));

      final sm2 = SessionStateMachine();
      sm2.transitionTo(SessionState.active);
      sm2.transitionTo(SessionState.onBreak);
      expect(sm2.canTransitionTo(SessionState.overridden), isTrue);
      sm2.transitionTo(SessionState.overridden);
      expect(sm2.currentState, equals(SessionState.overridden));
    });

    test('rejects invalid state transitions with StateError', () {
      final sm = SessionStateMachine();

      // Cannot jump from idle directly to onBreak or completed
      expect(() => sm.transitionTo(SessionState.onBreak), throwsStateError);
      expect(() => sm.transitionTo(SessionState.completed), throwsStateError);
      expect(() => sm.transitionTo(SessionState.overridden), throwsStateError);

      sm.transitionTo(SessionState.active);
      // Cannot jump from active back to idle or gracePeriod
      expect(() => sm.transitionTo(SessionState.idle), throwsStateError);
      expect(() => sm.transitionTo(SessionState.gracePeriod), throwsStateError);
      expect(() => sm.transitionTo(SessionState.cancelled), throwsStateError);
    });

    test(
        'tryTransitionTo returns false on illegal transitions without throwing',
        () {
      final sm = SessionStateMachine();
      expect(sm.tryTransitionTo(SessionState.completed), isFalse);
      expect(sm.currentState, equals(SessionState.idle));

      expect(sm.tryTransitionTo(SessionState.active), isTrue);
      expect(sm.currentState, equals(SessionState.active));
    });
  });
}
