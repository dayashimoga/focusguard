import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    stderr.writeln('coverage/lcov.info not found');
    exit(1);
  }
  final lines = file.readAsLinesSync();
  int totalFound = 0;
  int totalHit = 0;
  String currentFile = '';
  final fileStats = <String, List<int>>{};
  final unhitLinesPerFile = <String, List<int>>{};

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      fileStats[currentFile] = [0, 0];
      unhitLinesPerFile[currentFile] = [];
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      final lineNum = int.parse(parts[0]);
      final executionCount = int.parse(parts[1]);
      if (executionCount == 0 && currentFile.isNotEmpty) {
        unhitLinesPerFile[currentFile]!.add(lineNum);
      }
    } else if (line.startsWith('LF:')) {
      final f = int.parse(line.substring(3));
      totalFound += f;
      if (currentFile.isNotEmpty) fileStats[currentFile]![0] += f;
    } else if (line.startsWith('LH:')) {
      final h = int.parse(line.substring(3));
      totalHit += h;
      if (currentFile.isNotEmpty) fileStats[currentFile]![1] += h;
    }
  }

  stdout.writeln('=== FOCUSGUARD COVERAGE ANALYSIS ===');
  stdout.writeln('Total lines found: $totalFound');
  stdout.writeln('Total lines hit: $totalHit');
  final overallPct = totalFound > 0 ? (totalHit / totalFound * 100) : 0.0;
  stdout.writeln('Overall Coverage: ${overallPct.toStringAsFixed(2)}%');
  stdout.writeln('------------------------------------');

  // Category aggregates
  final categoryStats = <String, List<int>>{
    'domain': [0, 0],
    'engine': [0, 0],
    'persistence': [0, 0],
    'core': [0, 0],
    'presentation': [0, 0],
    'platform': [0, 0],
  };

  final sortedKeys = fileStats.keys.toList()..sort();
  for (final f in sortedKeys) {
    final stat = fileStats[f]!;
    final fPct =
        stat[0] > 0 ? (stat[1] / stat[0] * 100).toStringAsFixed(1) : '0';
    final unhit = unhitLinesPerFile[f] ?? [];
    final unhitStr = unhit.isNotEmpty ? ' [Unhit: ${unhit.join(", ")}]' : '';
    stdout.writeln('$f: $fPct% (${stat[1]}/${stat[0]})$unhitStr');

    for (final cat in categoryStats.keys) {
      if (f.startsWith('lib/$cat/')) {
        categoryStats[cat]![0] += stat[0];
        categoryStats[cat]![1] += stat[1];
      }
    }
  }

  stdout.writeln('\n=== CATEGORY SUMMARY ===');
  final categorySummary = <String, dynamic>{};
  int criticalFound = 0;
  int criticalHit = 0;

  for (final entry in categoryStats.entries) {
    final cat = entry.key;
    final f = entry.value[0];
    final h = entry.value[1];
    final pct = f > 0 ? (h / f * 100) : 0.0;
    stdout.writeln(
        '  ${cat.toUpperCase().padRight(14)}: ${pct.toStringAsFixed(2)}% ($h/$f)');
    categorySummary[cat] = {
      'linesFound': f,
      'linesHit': h,
      'percentage': pct,
    };
    if (cat == 'domain' || cat == 'engine' || cat == 'persistence') {
      criticalFound += f;
      criticalHit += h;
    }
  }

  final criticalPct =
      criticalFound > 0 ? (criticalHit / criticalFound * 100) : 0.0;
  stdout.writeln('------------------------------------');
  stdout.writeln(
      'CRITICAL DOMAINS (Domain+Engine+Persistence): ${criticalPct.toStringAsFixed(2)}% ($criticalHit/$criticalFound)');

  // Quality Gates
  const minOverallPct = 92.0;
  const minCriticalPct = 95.0;

  final overallPass = overallPct >= minOverallPct;
  final criticalPass = criticalPct >= minCriticalPct;

  stdout.writeln(
      'Quality Gate (Overall >= $minOverallPct%): ${overallPass ? "PASSED" : "FAILED"}');
  stdout.writeln(
      'Quality Gate (Critical >= $minCriticalPct%): ${criticalPass ? "PASSED" : "FAILED"}');

  // Write Evidence Artifact
  final evidenceDir = Directory('build/outputs/evidence');
  if (!evidenceDir.existsSync()) {
    evidenceDir.createSync(recursive: true);
  }

  final evidenceData = {
    'gateId': 'COV-001',
    'timestamp': DateTime.now().toUtc().toIso8601String(),
    'overallCoverage': overallPct,
    'criticalCoverage': criticalPct,
    'thresholds': {
      'minOverall': minOverallPct,
      'minCritical': minCriticalPct,
    },
    'status': (overallPass && criticalPass) ? 'PASSED' : 'FAILED',
    'totalLinesFound': totalFound,
    'totalLinesHit': totalHit,
    'categories': categorySummary,
    'fileDetails': {
      for (final f in sortedKeys)
        f: {
          'linesFound': fileStats[f]![0],
          'linesHit': fileStats[f]![1],
          'percentage': fileStats[f]![0] > 0
              ? (fileStats[f]![1] / fileStats[f]![0] * 100)
              : 0.0,
          'unhitLines': unhitLinesPerFile[f],
        }
    }
  };

  File('build/outputs/evidence/coverage_evidence.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(evidenceData),
  );
  stdout.writeln(
      'Wrote evidence artifact to build/outputs/evidence/coverage_evidence.json');

  if (!overallPass || !criticalPass) {
    stderr.writeln(
        '\nCoverage Gate Failed: Overall=$overallPct% (min $minOverallPct%), Critical=$criticalPct% (min $minCriticalPct%)');
    exit(1);
  }
}
