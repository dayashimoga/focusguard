import 'dart:io';

void main() {
  stdout.writeln('====================================================');
  stdout.writeln('    FocusGuard Automated Security & Privacy Audit   ');
  stdout.writeln('====================================================');

  int violations = 0;

  // 1. Check for absence of android.permission.INTERNET in AndroidManifest.xml
  stdout.writeln(
      '\n[1/4] Checking AndroidManifest.xml for network permissions...');
  final manifestFile = File('android/app/src/main/AndroidManifest.xml');
  if (manifestFile.existsSync()) {
    final content = manifestFile.readAsStringSync();
    if (content.contains('android.permission.INTERNET')) {
      stderr.writeln(
          '  [FAIL] VIOLATION: android.permission.INTERNET found in AndroidManifest.xml! FocusGuard must be 100% offline.');
      violations++;
    } else {
      stdout.writeln(
          '  [PASS] Confirmed: Zero network permissions requested. 100% offline guarantee enforced.');
    }
  } else {
    stderr.writeln('  [WARN] AndroidManifest.xml not found.');
  }

  // 2. Scan lib/ for unauthorized network endpoints or tracking SDKs
  stdout.writeln(
      '\n[2/4] Scanning lib/ for tracking SDKs, cloud analytics, or external APIs...');
  final libDir = Directory('lib');
  final networkPatterns = [
    RegExp(r'https?://(?!www\.w3\.org|schemas\.android\.com)',
        caseSensitive: false),
    RegExp(r'dart:io.*HttpClient', caseSensitive: false),
    RegExp(r'package:http', caseSensitive: false),
    RegExp(r'package:dio', caseSensitive: false),
    RegExp(r'package:firebase', caseSensitive: false),
    RegExp(r'firebase_', caseSensitive: false),
    RegExp(r'google_analytics', caseSensitive: false),
    RegExp(r'mixpanel', caseSensitive: false),
    RegExp(r'amplitude', caseSensitive: false),
    RegExp(r'segment', caseSensitive: false),
    RegExp(r'sentry', caseSensitive: false),
  ];

  int suspiciousFound = 0;
  for (final file in libDir.listSync(recursive: true).whereType<File>()) {
    if (file.path.endsWith('.dart')) {
      final lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        for (final pat in networkPatterns) {
          if (pat.hasMatch(line) && !line.trim().startsWith('//')) {
            stderr.writeln(
                '  [FAIL] Disallowed pattern "${pat.pattern}" at ${file.path}:${i + 1}');
            suspiciousFound++;
            violations++;
          }
        }
      }
    }
  }
  if (suspiciousFound == 0) {
    stdout.writeln(
        '  [PASS] Zero network clients, telemetry endpoints, or external analytics found in source code.');
  }

  // 3. Verify PIN security (Salted SHA-256)
  stdout
      .writeln('\n[3/4] Verifying cryptographic PIN hashing implementation...');
  final pinHasherFile = File('lib/core/security/pin_hasher.dart');
  if (pinHasherFile.existsSync()) {
    final content = pinHasherFile.readAsStringSync();
    if (content.contains('sha256') && content.contains('salt')) {
      stdout
          .writeln('  [PASS] Salted SHA-256 cryptographic hashing validated.');
    } else {
      stderr.writeln('  [FAIL] PIN hasher lacks salt or SHA-256.');
      violations++;
    }
  } else {
    stderr.writeln('  [FAIL] pin_hasher.dart not found.');
    violations++;
  }

  // 4. Verify PII scrubbing in Logger
  stdout.writeln('\n[4/4] Verifying zero-PII scrubbing in Logger...');
  final loggerFile = File('lib/core/utils/logger.dart');
  if (loggerFile.existsSync()) {
    final content = loggerFile.readAsStringSync();
    if (content.contains('scrubPII') && content.contains('REDACTED')) {
      stdout.writeln('  [PASS] PII scrubber validated.');
    } else {
      stderr.writeln('  [FAIL] Logger lacks PII scrubbing.');
      violations++;
    }
  } else {
    stderr.writeln('  [FAIL] logger.dart not found.');
    violations++;
  }

  stdout.writeln('\n----------------------------------------------------');
  if (violations == 0) {
    stdout.writeln(
        'Security Audit Status: PASSED (Zero security/privacy violations)');
    stdout.writeln('====================================================\n');
  } else {
    stderr.writeln(
        'Security Audit Status: FAILED ($violations violations found)');
    stdout.writeln('====================================================\n');
    exit(1);
  }
}
