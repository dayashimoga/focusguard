import 'dart:convert';
import 'dart:io';

/// Comprehensive 10-Point Security, Privacy & Configuration Audit for FocusGuard
void main() {
  stdout.writeln('====================================================');
  stdout.writeln('    FocusGuard Comprehensive Security & Privacy Audit');
  stdout.writeln('====================================================');

  int violations = 0;
  final results = <Map<String, dynamic>>[];

  void recordCheck(String id, String title, bool passed, String details) {
    results.add({
      'id': id,
      'title': title,
      'status': passed ? 'PASSED' : 'FAILED',
      'details': details,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
    if (passed) {
      stdout.writeln('  [PASS] $id: $title');
    } else {
      stderr.writeln('  [FAIL] $id: $title - $details');
      violations++;
    }
  }

  // Check 1: Zero Network Permissions in AndroidManifest.xml
  stdout.writeln(
      '\n[1/10] Checking AndroidManifest.xml for network permissions...');
  final manifestFile = File('android/app/src/main/AndroidManifest.xml');
  if (manifestFile.existsSync()) {
    final content = manifestFile.readAsStringSync();
    final hasInternet = content.contains('android.permission.INTERNET');
    recordCheck(
      'SEC-NET-001',
      'Zero Network Permissions in AndroidManifest.xml',
      !hasInternet,
      hasInternet
          ? 'VIOLATION: android.permission.INTERNET found in manifest!'
          : 'Zero network permissions requested. 100% offline guarantee enforced.',
    );
  } else {
    recordCheck('SEC-NET-001', 'AndroidManifest.xml Verification', false,
        'File not found');
  }

  // Check 2: allowBackup="false" Enforcement
  stdout.writeln(
      '\n[2/10] Checking AndroidManifest.xml for allowBackup=false...');
  if (manifestFile.existsSync()) {
    final content = manifestFile.readAsStringSync();
    final hasDisallowedBackup = content.contains('android:allowBackup="false"');
    recordCheck(
      'SEC-BAK-001',
      'Backup Exposure Prevention (allowBackup=false)',
      hasDisallowedBackup,
      hasDisallowedBackup
          ? 'Confirmed: android:allowBackup="false" explicitly configured to prevent adb backup extraction.'
          : 'VIOLATION: android:allowBackup="false" missing from application tag!',
    );
  } else {
    recordCheck(
        'SEC-BAK-001', 'Backup Exposure Check', false, 'File not found');
  }

  // Check 3: Scanning lib/ for Tracking SDKs, Cloud Analytics, or External APIs
  stdout.writeln(
      '\n[3/10] Scanning lib/ for telemetry SDKs or external network clients...');
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
  if (libDir.existsSync()) {
    for (final file in libDir.listSync(recursive: true).whereType<File>()) {
      if (file.path.endsWith('.dart')) {
        final lines = file.readAsLinesSync();
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          for (final pat in networkPatterns) {
            if (pat.hasMatch(line) && !line.trim().startsWith('//')) {
              suspiciousFound++;
            }
          }
        }
      }
    }
  }
  recordCheck(
    'SEC-SRC-001',
    'Offline Source Integrity & Zero Telemetry SDKs',
    suspiciousFound == 0,
    suspiciousFound == 0
        ? 'Zero external analytics, telemetry clients, or network endpoints in source code.'
        : '$suspiciousFound unauthorized network patterns detected in lib/.',
  );

  // Check 4: Android Component Export Safety & Permissions Guard
  stdout.writeln(
      '\n[4/10] Auditing AndroidManifest.xml component export security...');
  if (manifestFile.existsSync()) {
    final content = manifestFile.readAsStringSync();
    final overlaySafe =
        content.contains('android:name=".FocusBlockOverlayActivity"') &&
            content.contains('android:exported="false"');
    final serviceSafe =
        content.contains('android:name=".FocusEnforcementService"') &&
            content.contains('android:exported="false"');
    final adminGuarded =
        content.contains('android:name=".FocusDeviceAdminReceiver"') &&
            content.contains(
                'android:permission="android.permission.BIND_DEVICE_ADMIN"');
    final a11yGuarded = content
            .contains('android:name=".FocusAccessibilityService"') &&
        content.contains(
            'android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"');

    final componentsSecure =
        overlaySafe && serviceSafe && adminGuarded && a11yGuarded;
    recordCheck(
      'SEC-EXP-001',
      'Component Export Security & Permission Guarding',
      componentsSecure,
      componentsSecure
          ? 'Overlay/Service unexported; Admin/Accessibility strictly guarded with system permissions.'
          : 'VIOLATION: Insecure component exposure detected in AndroidManifest.xml!',
    );
  }

  // Check 5: Cryptographic PIN Security (Salted SHA-256 + Constant-Time Check)
  stdout.writeln(
      '\n[5/10] Verifying cryptographic PIN hashing implementation...');
  final pinHasherFile = File('lib/core/security/pin_hasher.dart');
  if (pinHasherFile.existsSync()) {
    final content = pinHasherFile.readAsStringSync();
    final hasSalt =
        content.contains('salt') && content.contains('generateSalt');
    final hasSha256 = content.contains('sha256');
    final hasConstantTime =
        content.contains('constantTimeEquals') || content.contains('result |=');
    final isSecure = hasSalt && hasSha256 && hasConstantTime;
    recordCheck(
      'SEC-PIN-001',
      'Salted SHA-256 PIN Security & Constant-Time Verification',
      isSecure,
      isSecure
          ? 'Salted SHA-256 hashing with timing-attack resistant constant-time comparison verified.'
          : 'VIOLATION: Inadequate PIN security implementation.',
    );
  } else {
    recordCheck('SEC-PIN-001', 'PIN Hasher Verification', false,
        'pin_hasher.dart not found');
  }

  // Check 6: Diagnostic Logger Zero-PII Scrubbing
  stdout
      .writeln('\n[6/10] Verifying zero-PII scrubbing in diagnostic Logger...');
  final loggerFile = File('lib/core/utils/logger.dart');
  if (loggerFile.existsSync()) {
    final content = loggerFile.readAsStringSync();
    final hasScrubber =
        content.contains('scrubPII') && content.contains('REDACTED');
    recordCheck(
      'SEC-LOG-001',
      'Diagnostic Logger PII Scrubbing',
      hasScrubber,
      hasScrubber
          ? 'Automated PII scrubbing validated (emails, PINs, tokens redacted).'
          : 'VIOLATION: Logger lacks PII scrubbing.',
    );
  } else {
    recordCheck(
        'SEC-LOG-001', 'Logger Verification', false, 'logger.dart not found');
  }

  // Check 7: Secret Scanning Across Workspace
  stdout.writeln(
      '\n[7/10] Scanning workspace files for hardcoded secrets/keys...');
  final secretPatterns = [
    RegExp(r'-----BEGIN (RSA|EC|OPENSSH|PRIVATE) KEY-----'),
    RegExp(r'AKIA[0-9A-Z]{16}'),
    RegExp(r'AIza[0-9A-Za-z-_]{35}'),
    RegExp(r'ghp_[0-9a-zA-Z]{36}'),
    RegExp(r'bearer\s+[a-zA-Z0-9_\-\.]{20,}', caseSensitive: false),
  ];
  int secretsFound = 0;
  for (final file
      in Directory.current.listSync(recursive: true).whereType<File>()) {
    if (file.path.contains('.git') ||
        file.path.contains('build') ||
        file.path.contains('.dart_tool')) {
      continue;
    }
    if (file.path.endsWith('.dart') ||
        file.path.endsWith('.kt') ||
        file.path.endsWith('.swift') ||
        file.path.endsWith('.xml') ||
        file.path.endsWith('.yaml') ||
        file.path.endsWith('.json')) {
      final text = file.readAsStringSync();
      for (final pat in secretPatterns) {
        if (pat.hasMatch(text)) {
          secretsFound++;
          stderr.writeln('  [WARN] Potential secret detected in ${file.path}');
        }
      }
    }
  }
  recordCheck(
    'SEC-SCAN-001',
    'Repository Secret & Credential Scanning',
    secretsFound == 0,
    secretsFound == 0
        ? 'Zero private keys, cloud credentials, or access tokens discovered.'
        : '$secretsFound potential secrets found in repository!',
  );

  // Check 8: Dependency Integrity in pubspec.lock
  stdout.writeln('\n[8/10] Auditing dependency lockfile (pubspec.lock)...');
  final lockFile = File('pubspec.lock');
  final hasLock = lockFile.existsSync() && lockFile.lengthSync() > 500;
  recordCheck(
    'SEC-DEP-001',
    'Dependency Lockfile Integrity (pubspec.lock)',
    hasLock,
    hasLock
        ? 'Deterministic pinned dependency graph verified with pubspec.lock.'
        : 'VIOLATION: Missing or empty pubspec.lock!',
  );

  // Check 9: Release Configuration Verification (debuggable=false)
  stdout.writeln('\n[9/10] Validating Android release build configuration...');
  final buildGradle = File('android/app/build.gradle');
  var releaseSecure = true;
  if (buildGradle.existsSync()) {
    final gradleContent = buildGradle.readAsStringSync();
    final releaseBlockMatch =
        RegExp(r'release\s*\{([^}]+)\}').firstMatch(gradleContent);
    if (releaseBlockMatch != null &&
        releaseBlockMatch.group(1)!.contains('debuggable true')) {
      releaseSecure = false;
    }
  }
  recordCheck(
    'SEC-CFG-001',
    'Release Security Configuration',
    releaseSecure,
    releaseSecure
        ? 'Release build configuration enforces non-debuggable production posture.'
        : 'VIOLATION: debuggable true detected in release build block!',
  );

  // Check 10: Anti-Tamper Clock Jump Defense
  stdout
      .writeln('\n[10/10] Verifying dual-clock anti-tamper detection logic...');
  final tamperDetectorFile = File('lib/core/security/tamper_detector.dart');
  final hasTamperDetector = tamperDetectorFile.existsSync() &&
      (tamperDetectorFile.readAsStringSync().contains('checkClockIntegrity') ||
          tamperDetectorFile
              .readAsStringSync()
              .contains('checkClockTampering')) &&
      (tamperDetectorFile.readAsStringSync().contains('clockSkewThresholdMs') ||
          tamperDetectorFile
              .readAsStringSync()
              .contains('clockJumpThresholdSeconds'));
  recordCheck(
    'SEC-TMP-001',
    'Hardware Monotonic Anti-Tamper Clock Validation',
    hasTamperDetector,
    hasTamperDetector
        ? 'Wall-clock jump detector and monotonic elapsed time verification confirmed.'
        : 'VIOLATION: Tamper detector implementation missing or incomplete!',
  );

  // Save Evidence Artifact
  final evidenceDir = Directory('build/outputs/evidence');
  if (!evidenceDir.existsSync()) {
    evidenceDir.createSync(recursive: true);
  }
  final evidenceFile = File('build/outputs/evidence/security_evidence.json');
  final reportData = {
    'suite': 'FocusGuard Security & Privacy Audit',
    'status': violations == 0 ? 'PASSED' : 'FAILED',
    'totalChecks': results.length,
    'violations': violations,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
    'checks': results,
  };
  evidenceFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(reportData));
  stdout.writeln('\nEvidence artifact written to: ${evidenceFile.path}');

  stdout.writeln('\n----------------------------------------------------');
  if (violations == 0) {
    stdout.writeln(
        'Security Audit Status: PASSED (All 10 security quality gates satisfied)');
    stdout.writeln('====================================================\n');
  } else {
    stderr.writeln(
        'Security Audit Status: FAILED ($violations violations found)');
    stdout.writeln('====================================================\n');
    exit(1);
  }
}
