import 'dart:convert';
import 'dart:io';

void main() {
  stdout.writeln('Generating Software Bill of Materials (SBOM)...');

  final pubspecLock = File('pubspec.lock');
  if (!pubspecLock.existsSync()) {
    stderr.writeln('Error: pubspec.lock not found.');
    exit(1);
  }

  final lines = pubspecLock.readAsLinesSync();
  final packages = <Map<String, dynamic>>[];

  String? currentPackage;
  String? currentVersion;
  String? currentType;
  String? currentUrl;

  for (final line in lines) {
    final trimmed = line.trim();
    if (line.startsWith('  ') &&
        !line.startsWith('    ') &&
        trimmed.endsWith(':')) {
      if (currentPackage != null && currentVersion != null) {
        packages.add({
          'name': currentPackage,
          'version': currentVersion,
          'type': currentType ?? 'direct',
          'source': currentUrl ?? 'hosted',
          'purl': 'pkg:pub/$currentPackage@$currentVersion',
        });
      }
      currentPackage = trimmed.replaceAll(':', '');
      currentVersion = null;
      currentType = null;
      currentUrl = null;
    } else if (trimmed.startsWith('version:')) {
      currentVersion =
          trimmed.replaceFirst('version:', '').trim().replaceAll('"', '');
    } else if (trimmed.startsWith('dependency:')) {
      currentType =
          trimmed.replaceFirst('dependency:', '').trim().replaceAll('"', '');
    } else if (trimmed.startsWith('url:')) {
      currentUrl = trimmed.replaceFirst('url:', '').trim().replaceAll('"', '');
    }
  }

  if (currentPackage != null && currentVersion != null) {
    packages.add({
      'name': currentPackage,
      'version': currentVersion,
      'type': currentType ?? 'direct',
      'source': currentUrl ?? 'hosted',
      'purl': 'pkg:pub/$currentPackage@$currentVersion',
    });
  }

  final sbom = {
    'bomFormat': 'CycloneDX',
    'specVersion': '1.5',
    'serialNumber':
        'urn:uuid:focusguard-${DateTime.now().millisecondsSinceEpoch}',
    'version': 1,
    'metadata': {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'tools': [
        {
          'vendor': 'FocusGuard Team',
          'name': 'FocusGuard SBOM Generator',
          'version': '1.0.0'
        }
      ],
      'component': {
        'name': 'FocusGuard',
        'version': '1.0.0+1',
        'type': 'application',
        'description':
            'Production-grade privacy-first digital wellbeing and screen time restriction platform',
        'licenses': [
          {
            'license': {'id': 'MIT'}
          }
        ]
      }
    },
    'components': packages
        .map((pkg) => {
              'type': 'library',
              'name': pkg['name'],
              'version': pkg['version'],
              'purl': pkg['purl'],
              'scope': pkg['type'] == 'direct main' ? 'required' : 'optional',
            })
        .toList(),
  };

  final outDir = Directory('build/outputs');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final outFile = File('build/outputs/sbom.json');
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(sbom));
  stdout.writeln(
      'Successfully generated SBOM with ${packages.length} dependencies at ${outFile.path}');
}
