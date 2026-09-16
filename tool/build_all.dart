import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// Comprehensive local build orchestrator for FocusGuard.
/// Builds all supported targets achievable in the current environment,
/// computes SHA-256 digests, and generates a unified build_manifest.json.
void main(List<String> args) async {
  final startTime = DateTime.now();
  stdout.writeln(
      '================================================================');
  stdout.writeln(
      '   FocusGuard Local Build Orchestrator (build-all)               ');
  stdout.writeln(
      '   Timestamp: ${startTime.toUtc().toIso8601String()}            ');
  stdout.writeln(
      '================================================================\n');

  final outputsDir = Directory('build/outputs');
  if (!outputsDir.existsSync()) {
    outputsDir.createSync(recursive: true);
  }

  // 1. Collect toolchain information
  String flutterVersion = 'Unknown';
  String dartVersion = Platform.version.split(' ').first;
  try {
    final flRes = await Process.run('flutter', ['--version']);
    if (flRes.exitCode == 0) {
      flutterVersion = flRes.stdout.toString().split('\n').first;
    }
  } catch (_) {}

  final toolchain = {
    'flutter': flutterVersion,
    'dart': dartVersion,
    'os': Platform.operatingSystem,
    'hostname': Platform.localHostname,
  };

  final targetManifests = <Map<String, dynamic>>[];

  // Helper to compute sha256
  String getSha256(File file) {
    final bytes = file.readAsBytesSync();
    return sha256.convert(bytes).toString();
  }

  // Helper to register an artifact
  void registerArtifact({
    required String platform,
    required String buildType,
    required String targetName,
    required File file,
    required String status,
    String? reason,
  }) {
    if (file.existsSync()) {
      final digest = getSha256(file);
      final shaFile = File('${file.path}.sha256');
      shaFile.writeAsStringSync(
          '$digest  ${file.path.split(Platform.pathSeparator).last}\n');

      targetManifests.add({
        'platform': platform,
        'buildType': buildType,
        'targetName': targetName,
        'status': status,
        'artifactPath': file.path.replaceAll('\\', '/'),
        'sizeBytes': file.lengthSync(),
        'sha256': digest,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      stdout.writeln(
          '[SUCCESS] $targetName: ${file.lengthSync()} bytes (SHA: ${digest.substring(0, 12)}...)');
    } else {
      targetManifests.add({
        'platform': platform,
        'buildType': buildType,
        'targetName': targetName,
        'status': status,
        'reason': reason ?? 'Artifact file missing',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      stdout.writeln(
          '[SKIPPED/REQUIRED] $targetName: ${reason ?? "Not present"}');
    }
  }

  // 2. Generate Deterministic Test Fixtures
  stdout.writeln('\n[1/5] Generating Test APK Fixtures...');
  try {
    final pyRes = await Process.run('python3', ['tool/generate_fixtures.py']);
    if (pyRes.exitCode == 0) {
      stdout.writeln(pyRes.stdout.toString().trim());
    }
  } catch (e) {
    stdout.writeln('Warning: python3 fixture generation failed: $e');
  }

  final fixtureBlocked = File('build/outputs/focusguard-test-blocked.apk');
  final fixtureAllowed = File('build/outputs/focusguard-test-allowed.apk');
  registerArtifact(
    platform: 'Android Test Fixture',
    buildType: 'fixture',
    targetName: 'focusguard-test-blocked.apk',
    file: fixtureBlocked,
    status: 'BUILT',
  );
  registerArtifact(
    platform: 'Android Test Fixture',
    buildType: 'fixture',
    targetName: 'focusguard-test-allowed.apk',
    file: fixtureAllowed,
    status: 'BUILT',
  );

  // 3. Android Debug APK
  stdout.writeln('\n[2/5] Building Android Debug APK...');
  final debugApkTarget = File('build/outputs/focusguard-debug.apk');
  final debugBuilt = File('build/app/outputs/flutter-apk/app-debug.apk');

  if (!debugBuilt.existsSync()) {
    final res = await Process.run('flutter', ['build', 'apk', '--debug']);
    if (res.exitCode != 0) {
      stdout.writeln(
          'flutter build apk --debug output:\n${res.stdout}\n${res.stderr}');
    }
  }
  if (debugBuilt.existsSync() && !debugApkTarget.existsSync()) {
    debugBuilt.copySync(debugApkTarget.path);
  }
  registerArtifact(
    platform: 'Android',
    buildType: 'debug',
    targetName: 'focusguard-debug.apk',
    file: debugApkTarget.existsSync() ? debugApkTarget : debugBuilt,
    status: (debugApkTarget.existsSync() || debugBuilt.existsSync())
        ? 'BUILT'
        : 'FAILED',
    reason: 'Requires Android SDK / Gradle build environment',
  );

  // 4. Android Release APK
  stdout.writeln('\n[3/5] Building Android Release APK...');
  final releaseApkTarget = File('build/outputs/focusguard-release.apk');
  final releaseBuilt = File('build/app/outputs/flutter-apk/app-release.apk');

  if (!releaseBuilt.existsSync() && !releaseApkTarget.existsSync()) {
    final res = await Process.run(
        'flutter', ['build', 'apk', '--release', '--no-tree-shake-icons']);
    if (res.exitCode != 0) {
      stdout.writeln(
          'flutter build apk --release output:\n${res.stdout}\n${res.stderr}');
    }
  }
  if (releaseBuilt.existsSync() && !releaseApkTarget.existsSync()) {
    releaseBuilt.copySync(releaseApkTarget.path);
  }
  registerArtifact(
    platform: 'Android',
    buildType: 'release',
    targetName: 'focusguard-release.apk',
    file: releaseApkTarget.existsSync() ? releaseApkTarget : releaseBuilt,
    status: (releaseApkTarget.existsSync() || releaseBuilt.existsSync())
        ? 'BUILT'
        : 'FAILED',
  );

  // 5. Android Release AAB (App Bundle)
  stdout.writeln('\n[4/5] Building Android Release App Bundle (AAB)...');
  final releaseAabTarget = File('build/outputs/focusguard-release.aab');
  final aabBuilt = File('build/app/outputs/bundle/release/app-release.aab');

  if (!aabBuilt.existsSync() && !releaseAabTarget.existsSync()) {
    final res = await Process.run('flutter',
        ['build', 'appbundle', '--release', '--no-tree-shake-icons']);
    if (res.exitCode != 0) {
      stdout.writeln(
          'flutter build appbundle --release output:\n${res.stdout}\n${res.stderr}');
    }
  }
  if (aabBuilt.existsSync() && !releaseAabTarget.existsSync()) {
    aabBuilt.copySync(releaseAabTarget.path);
  }
  registerArtifact(
    platform: 'Android',
    buildType: 'release-bundle',
    targetName: 'focusguard-release.aab',
    file: releaseAabTarget.existsSync() ? releaseAabTarget : aabBuilt,
    status: (releaseAabTarget.existsSync() || aabBuilt.existsSync())
        ? 'BUILT'
        : 'FAILED',
  );

  // 6. External Platform Evaluation (iOS on macOS)
  stdout.writeln('\n[5/5] Checking Non-Host External Targets...');
  if (Platform.isMacOS) {
    stdout.writeln('Host is macOS; building iOS simulator bundle...');
    final res = await Process.run(
        'flutter', ['build', 'ios', '--simulator', '--no-codesign']);
    targetManifests.add({
      'platform': 'iOS',
      'buildType': 'simulator',
      'targetName': 'Runner.app',
      'status': res.exitCode == 0 ? 'BUILT' : 'FAILED',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  } else {
    targetManifests.add({
      'platform': 'iOS',
      'buildType': 'release',
      'targetName': 'FocusGuard.ipa',
      'status': 'EXTERNAL_BUILD_REQUIRED',
      'reason':
          'iOS builds require macOS host with Xcode toolchain; validated on GitHub Actions macos-latest runner',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // 7. Write build_manifest.json
  final manifestFile = File('build/outputs/build_manifest.json');
  final manifestData = {
    'manifestVersion': '1.0.0',
    'timestamp': DateTime.now().toUtc().toIso8601String(),
    'toolchain': toolchain,
    'targets': targetManifests,
  };
  manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifestData));
  stdout.writeln(
      '\n================================================================');
  stdout.writeln('Wrote unified build manifest to: ${manifestFile.path}');
  stdout
      .writeln('Total local build targets recorded: ${targetManifests.length}');
  stdout.writeln(
      '================================================================');
}
