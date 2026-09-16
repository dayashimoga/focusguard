import '../models/enums.dart';

/// Deterministic finite state machine governing Focus Session transitions.
class SessionStateMachine {
  SessionState _currentState;

  SessionStateMachine([SessionState initialState = SessionState.idle])
      : _currentState = initialState;

  SessionState get currentState => _currentState;

  /// Defines valid transition paths
  static const Map<SessionState, Set<SessionState>> validTransitions = {
    SessionState.idle: {SessionState.gracePeriod, SessionState.active},
    SessionState.gracePeriod: {SessionState.active, SessionState.cancelled},
    SessionState.active: {
      SessionState.onBreak,
      SessionState.overrideRequested,
      SessionState.overrideValidating,
      SessionState.ending,
      SessionState.overridden,
      SessionState.expired,
      SessionState.completed,
    },
    SessionState.onBreak: {
      SessionState.active,
      SessionState.overrideRequested,
      SessionState.overrideValidating,
      SessionState.ending,
      SessionState.overridden,
      SessionState.completed,
    },
    SessionState.overrideRequested: {
      SessionState.overrideValidating,
      SessionState.active,
      SessionState.ending,
    },
    SessionState.overrideValidating: {
      SessionState.ending,
      SessionState.active,
    },
    SessionState.ending: {
      SessionState.overridden,
      SessionState.completed,
    },
    SessionState.expired: {
      SessionState.completed,
      SessionState.ending,
    },
    SessionState.overridden: {SessionState.idle},
    SessionState.completed: {SessionState.idle},
    SessionState.cancelled: {SessionState.idle},
  };

  /// Checks whether transition to [nextState] is allowed.
  bool canTransitionTo(SessionState nextState) {
    final allowed = validTransitions[_currentState];
    return allowed != null && allowed.contains(nextState);
  }

  /// Transitions state if valid, otherwise throws [StateError].
  SessionState transitionTo(SessionState nextState) {
    if (!canTransitionTo(nextState)) {
      throw StateError(
          'Invalid session transition from $_currentState to $nextState');
    }
    _currentState = nextState;
    return _currentState;
  }

  /// Safe transition that returns true on success, false on invalid transition without throwing.
  bool tryTransitionTo(SessionState nextState) {
    if (canTransitionTo(nextState)) {
      _currentState = nextState;
      return true;
    }
    return false;
  }

  /// Resets state machine back to idle.
  void reset() {
    _currentState = SessionState.idle;
  }

  /// Forces state during session state recovery and persistence restoration.
  void forceState(SessionState state) {
    _currentState = state;
  }
}
