/// Base class for all typed FocusGuard domain exceptions.
/// These exceptions map internal failures to safe, user-friendly, actionable messages,
/// completely preventing raw stack traces or internal StateErrors from leaking into UI.
abstract class DomainException implements Exception {
  final String userMessage;
  final String? technicalDetail;

  const DomainException({
    required this.userMessage,
    this.technicalDetail,
  });

  @override
  String toString() => userMessage;
}

/// Exception thrown when an override attempt fails friction requirements or policy validation.
/// Extends [StateError] for compatibility with test assertions while implementing [DomainException]
/// to provide safe, actionable UI messages.
class OverrideValidationException extends StateError
    implements DomainException {
  @override
  final String userMessage;
  @override
  final String? technicalDetail;

  OverrideValidationException({
    required this.userMessage,
    this.technicalDetail,
  }) : super(technicalDetail ?? userMessage);

  factory OverrideValidationException.phraseMismatch() =>
      OverrideValidationException(
        userMessage:
            'Phrase doesn\'t match. Type the confirmation phrase exactly.',
        technicalDetail:
            'The entered phrase does not match the safety confirmation phrase',
      );

  factory OverrideValidationException.reasonTooShort() =>
      OverrideValidationException(
        userMessage: 'Please provide an explanation of at least 5 characters.',
        technicalDetail:
            'A typed explanation of at least 5 characters is required',
      );

  factory OverrideValidationException.incorrectPin() =>
      OverrideValidationException(
        userMessage: 'Incorrect PIN entered. Please try again.',
        technicalDetail: 'Incorrect PIN entered',
      );

  factory OverrideValidationException.quotaExhausted(int used, int max) =>
      OverrideValidationException(
        userMessage:
            'Daily override quota has been reached ($used of $max used).',
        technicalDetail: 'Daily override quota has been exhausted',
      );

  factory OverrideValidationException.cooldownActive(int remainingSeconds) =>
      OverrideValidationException(
        userMessage:
            'Cooldown timer active. Please wait $remainingSeconds seconds.',
        technicalDetail: 'Cooldown countdown active',
      );

  factory OverrideValidationException.disabled(String typeName) =>
      OverrideValidationException(
        userMessage:
            'This override method is not enabled for the current profile.',
        technicalDetail: 'Override type not enabled',
      );

  factory OverrideValidationException.noActiveSession() =>
      OverrideValidationException(
        userMessage: 'No active focus session found to exit.',
        technicalDetail: 'No active session to override',
      );

  factory OverrideValidationException.inProgress() =>
      OverrideValidationException(
        userMessage: 'An exit request is already being processed.',
        technicalDetail: 'Exit transition in progress',
      );
}

/// Exception thrown when an invalid session lifecycle transition is attempted.
class SessionTransitionException extends StateError implements DomainException {
  @override
  final String userMessage;
  @override
  final String? technicalDetail;

  SessionTransitionException({
    required this.userMessage,
    this.technicalDetail,
  }) : super(technicalDetail ?? userMessage);

  factory SessionTransitionException.invalid(String from, String to) =>
      SessionTransitionException(
        userMessage: 'The session cannot change from $from to $to.',
        technicalDetail: 'Invalid state machine transition: $from -> $to',
      );
}

/// Exception thrown when native enforcement operations encounter failures.
class PlatformEnforcementException extends StateError
    implements DomainException {
  @override
  final String userMessage;
  @override
  final String? technicalDetail;

  PlatformEnforcementException({
    required this.userMessage,
    this.technicalDetail,
  }) : super(technicalDetail ?? userMessage);

  factory PlatformEnforcementException.communicationError(String detail) =>
      PlatformEnforcementException(
        userMessage:
            'Unable to communicate with device restriction services. Please check app permissions.',
        technicalDetail: detail,
      );
}
