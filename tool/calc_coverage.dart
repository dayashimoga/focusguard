import 'dart:io';

void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    print('coverage/lcov.info not found');
    return;
  }
  final lines = file.readAsLinesSync();
  int found = 0;
  int hit = 0;
  String currentFile = '';
  final fileStats = <String, List<int>>{};

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      fileStats[currentFile] = [0, 0];
    } else if (line.startsWith('LF:')) {
      final f = int.parse(line.substring(3));
      found += f;
      if (currentFile.isNotEmpty) fileStats[currentFile]![0] += f;
    } else if (line.startsWith('LH:')) {
      final h = int.parse(line.substring(3));
      hit += h;
      if (currentFile.isNotEmpty) fileStats[currentFile]![1] += h;
    }
  }

  print('=== COVERAGE SUMMARY ===');
  print('Total lines found: $found');
  print('Total lines hit: $hit');
  final pct = found > 0 ? (hit / found * 100).toStringAsFixed(2) : '0';
  print('Overall Coverage: $pct%');
  print('------------------------');

  // Sort files by coverage
  final sortedKeys = fileStats.keys.toList()..sort();
  for (final f in sortedKeys) {
    final stat = fileStats[f]!;
    final fPct =
        stat[0] > 0 ? (stat[1] / stat[0] * 100).toStringAsFixed(1) : '0';
    print('$f: $fPct% (${stat[1]}/${stat[0]})');
  }
}
