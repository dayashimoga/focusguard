import 'dart:developer' as developer;

/// Privacy-safe diagnostic logger that sanitizes potential PII before writing.
class AppLogger {
  AppLogger._();

  static const bool isDebugMode = true;

  // Regex patterns to scrub sensitive data
  static final RegExp _emailRegex =
      RegExp(r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+');
  static final RegExp _pinRegex = RegExp(r'\b\d{4,8}\b');

  /// Logs an info-level message.
  static void info(String message, {String tag = 'FocusGuard'}) {
    _log('INFO', tag, message);
  }

  /// Logs a warning-level message.
  static void warn(String message, {String tag = 'FocusGuard'}) {
    _log('WARN', tag, message);
  }

  /// Logs an error-level message with optional exception.
  static void error(String message,
      {Object? error, StackTrace? stackTrace, String tag = 'FocusGuard'}) {
    _log('ERROR', tag, message);
    if (error != null) {
      developer.log('[$tag] Error details: $error', stackTrace: stackTrace);
    }
  }

  /// Logs a debug-level message.
  static void debug(String message, {String tag = 'FocusGuard'}) {
    if (isDebugMode) {
      _log('DEBUG', tag, message);
    }
  }

  static void _log(String level, String tag, String message) {
    final sanitized = _sanitize(message);
    developer.log('[$level][$tag] $sanitized');
  }

  /// Replaces identifiable secrets or PII with redacted tokens.
  static String scrubPII(String input) => _sanitize(input);

  static String _sanitize(String input) {
    var output = input.replaceAll(_emailRegex, '[REDACTED_EMAIL]');
    // Avoid redacting timestamps or duration numbers by only checking PIN fields if tagged
    if (output.toLowerCase().contains('pin') ||
        output.toLowerCase().contains('secret')) {
      output = output.replaceAll(_pinRegex, '[REDACTED_PIN]');
    }
    return output;
  }
}
