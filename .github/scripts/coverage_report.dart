import 'dart:io';

const coverageThreshold = 91.78;
const changedCoverageThreshold = 90.0;
const domainNames = <String>[
  'models',
  'services',
  'controllers',
  'screens',
  'widgets',
  'validation',
  'utils',
  'racine de lib',
];

class CoverageInputException implements Exception {
  const CoverageInputException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FileCoverage {
  const FileCoverage(this.path, this.lines);

  final String path;
  final Map<int, int> lines;

  int get covered => lines.values.where((hits) => hits > 0).length;
  int get total => lines.length;
  double get percentage => covered * 100 / total;
}

class DomainCoverage {
  const DomainCoverage(this.name, this.covered, this.total);

  final String name;
  final int covered;
  final int total;

  double? get percentage => total == 0 ? null : covered * 100 / total;
}

class CoverageSummary {
  const CoverageSummary({
    required this.covered,
    required this.total,
    required this.threshold,
    required this.domains,
    required this.zeroCoverageFiles,
    required this.filesBelowEighty,
  });

  final int covered;
  final int total;
  final double threshold;
  final List<DomainCoverage> domains;
  final List<FileCoverage> zeroCoverageFiles;
  final List<FileCoverage> filesBelowEighty;

  double get percentage => covered * 100 / total;
  bool get passesThreshold => reportedPercentage(percentage) >= threshold;
}

class ChangedLines {
  const ChangedLines.available(this.lines) : reason = null;
  const ChangedLines.unavailable(this.reason) : lines = null;

  final Map<String, Set<int>>? lines;
  final String? reason;

  bool get isAvailable => lines != null;
}

class ChangedCoverage {
  const ChangedCoverage.available({required this.covered, required this.total})
    : reason = null;

  const ChangedCoverage.unavailable(this.reason) : covered = null, total = null;

  final int? covered;
  final int? total;
  final String? reason;

  bool get isAvailable => covered != null && total != null;
  double? get percentage => isAvailable ? covered! * 100 / total! : null;
  bool get passesThreshold =>
      !isAvailable ||
      reportedPercentage(percentage!) >= changedCoverageThreshold;
}

class CoverageReportResult {
  const CoverageReportResult({
    required this.summary,
    required this.changedCoverage,
    required this.markdown,
  });

  final CoverageSummary summary;
  final ChangedCoverage changedCoverage;
  final String markdown;
}

String normalizeSourcePath(String sourcePath) {
  final normalized = sourcePath.replaceAll('\\', '/');
  if (normalized.startsWith('lib/')) return normalized;

  final libMarker = normalized.lastIndexOf('/lib/');
  return libMarker == -1 ? normalized : normalized.substring(libMarker + 1);
}

Map<String, Map<int, int>> parseLcov(String contents) {
  if (contents.trim().isEmpty) {
    throw const CoverageInputException('Le rapport LCOV est vide.');
  }

  final files = <String, Map<int, int>>{};
  String? currentPath;
  Map<int, int>? currentLines;

  void mergeCurrentRecord() {
    final sourcePath = normalizeSourcePath(currentPath!);
    if (!sourcePath.startsWith('lib/') || !sourcePath.endsWith('.dart')) {
      return;
    }
    if (currentLines!.isEmpty) return;

    final lines = files.putIfAbsent(sourcePath, () => <int, int>{});
    for (final entry in currentLines!.entries) {
      final previousHits = lines[entry.key] ?? 0;
      lines[entry.key] = entry.value > previousHits
          ? entry.value
          : previousHits;
    }
  }

  for (final rawLine in contents.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    if (line.startsWith('SF:')) {
      if (currentPath != null) {
        throw const CoverageInputException(
          "Le rapport LCOV est invalide : fin d'enregistrement manquante.",
        );
      }

      final sourcePath = line.substring(3);
      if (sourcePath.isEmpty) {
        throw const CoverageInputException(
          'Le rapport LCOV est invalide : chemin de source manquant.',
        );
      }
      currentPath = sourcePath;
      currentLines = <int, int>{};
      continue;
    }

    if (line.startsWith('DA:')) {
      if (currentPath == null) {
        throw const CoverageInputException(
          'Le rapport LCOV est invalide : donnée de ligne sans source.',
        );
      }

      final match = RegExp(r'^DA:(\d+),(\d+)(?:,[^,]+)?$').firstMatch(line);
      final lineNumber = match == null ? null : int.tryParse(match.group(1)!);
      final hits = match == null ? null : int.tryParse(match.group(2)!);
      if (lineNumber == null || lineNumber < 1 || hits == null) {
        throw CoverageInputException(
          "Le rapport LCOV est invalide : donnée de ligne incorrecte '$line'.",
        );
      }

      final previousHits = currentLines![lineNumber] ?? 0;
      currentLines[lineNumber] = hits > previousHits ? hits : previousHits;
      continue;
    }

    if (line == 'end_of_record') {
      if (currentPath == null) {
        throw const CoverageInputException(
          "Le rapport LCOV est invalide : fin d'enregistrement sans source.",
        );
      }
      mergeCurrentRecord();
      currentPath = null;
      currentLines = null;
    }
  }

  if (currentPath != null) {
    throw const CoverageInputException(
      "Le rapport LCOV est invalide : fin d'enregistrement manquante.",
    );
  }

  final instrumentableLines = files.values.fold<int>(
    0,
    (total, lines) => total + lines.length,
  );
  if (files.isEmpty || instrumentableLines == 0) {
    throw const CoverageInputException(
      'Le rapport LCOV ne contient aucune ligne Dart instrumentable sous lib/.',
    );
  }

  return files;
}

Map<String, Map<int, int>> readLcov(String lcovPath) {
  final file = File(lcovPath);
  if (!file.existsSync()) {
    throw CoverageInputException('Rapport LCOV absent : $lcovPath.');
  }
  return parseLcov(file.readAsStringSync());
}

String? domainFor(String sourcePath) {
  final relativePath = sourcePath.substring('lib/'.length);
  if (!relativePath.contains('/')) return 'racine de lib';

  final domain = relativePath.split('/').first;
  return domainNames.contains(domain) ? domain : null;
}

CoverageSummary summarizeCoverage(
  Map<String, Map<int, int>> files, {
  double threshold = coverageThreshold,
}) {
  final fileSummaries =
      files.entries
          .map((entry) => FileCoverage(entry.key, entry.value))
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));
  final domainTotals = {
    for (final name in domainNames) name: [0, 0],
  };
  var covered = 0;
  var total = 0;

  for (final file in fileSummaries) {
    covered += file.covered;
    total += file.total;
    final domain = domainFor(file.path);
    if (domain != null) {
      domainTotals[domain]![0] += file.covered;
      domainTotals[domain]![1] += file.total;
    }
  }

  return CoverageSummary(
    covered: covered,
    total: total,
    threshold: threshold,
    domains: [
      for (final name in domainNames)
        DomainCoverage(name, domainTotals[name]![0], domainTotals[name]![1]),
    ],
    zeroCoverageFiles: fileSummaries
        .where((file) => file.covered == 0)
        .toList(),
    filesBelowEighty: fileSummaries
        .where((file) => file.percentage < 80)
        .toList(),
  );
}

Map<String, Set<int>> parseChangedLines(String diff) {
  final changedLines = <String, Set<int>>{};
  String? sourcePath;

  for (final line in diff.split(RegExp(r'\r?\n'))) {
    if (line.startsWith('+++ ')) {
      final candidate = line.substring(4);
      sourcePath = candidate == '/dev/null'
          ? null
          : normalizeSourcePath(candidate.replaceFirst(RegExp(r'^b/'), ''));
      if (sourcePath != null &&
          (!sourcePath.startsWith('lib/') || !sourcePath.endsWith('.dart'))) {
        sourcePath = null;
      }
      continue;
    }

    final hunk = RegExp(
      r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@',
    ).firstMatch(line);
    if (hunk == null || sourcePath == null) continue;

    final start = int.parse(hunk.group(1)!);
    final count = hunk.group(2) == null ? 1 : int.parse(hunk.group(2)!);
    final fileLines = changedLines.putIfAbsent(sourcePath, () => <int>{});
    for (var lineNumber = start; lineNumber < start + count; lineNumber++) {
      fileLines.add(lineNumber);
    }
  }

  return changedLines;
}

ChangedLines loadChangedLines(
  String? baseSha,
  String? headSha,
  String workspace,
) {
  if (baseSha == null ||
      baseSha.isEmpty ||
      headSha == null ||
      headSha.isEmpty) {
    return const ChangedLines.unavailable(
      'contexte de pull request indisponible',
    );
  }

  ProcessResult result;
  try {
    result = Process.runSync('git', [
      'diff',
      '--unified=0',
      '--no-color',
      '--find-renames',
      '$baseSha...$headSha',
      '--',
      'lib',
    ], workingDirectory: workspace);
  } on ProcessException catch (error) {
    return ChangedLines.unavailable('diff Git indisponible ($error)');
  }
  if (result.exitCode != 0) {
    final diagnostic = result.stderr.toString().trim();
    return ChangedLines.unavailable(
      'diff Git indisponible${diagnostic.isEmpty ? '' : ' ($diagnostic)'}',
    );
  }

  return ChangedLines.available(parseChangedLines(result.stdout.toString()));
}

ChangedCoverage summarizeChangedCoverage(
  Map<String, Map<int, int>> files,
  ChangedLines changed,
) {
  if (!changed.isAvailable) {
    return ChangedCoverage.unavailable(changed.reason!);
  }

  var covered = 0;
  var total = 0;
  for (final entry in changed.lines!.entries) {
    final instrumentedLines = files[entry.key];
    if (instrumentedLines == null) continue;

    for (final lineNumber in entry.value) {
      if (!instrumentedLines.containsKey(lineNumber)) continue;
      total++;
      if (instrumentedLines[lineNumber]! > 0) covered++;
    }
  }

  if (total == 0) {
    return const ChangedCoverage.unavailable(
      'aucune ligne Dart instrumentable ajoutée ou modifiée',
    );
  }
  return ChangedCoverage.available(covered: covered, total: total);
}

String formatPercentage(double? value) {
  return value == null ? 'N/A' : '${value.toStringAsFixed(2)} %';
}

double reportedPercentage(double value) {
  return double.parse(value.toStringAsFixed(2));
}

String escapeTableCell(Object value) {
  return value.toString().replaceAll('|', r'\|').replaceAll('\n', ' ');
}

String filesTable(List<FileCoverage> files) {
  if (files.isEmpty) return 'Aucun fichier.';

  return [
    '| Fichier | Lignes couvertes | Couverture |',
    '| --- | ---: | ---: |',
    for (final file in files)
      '| ${escapeTableCell(file.path)} | ${file.covered} / ${file.total} | '
          '${formatPercentage(file.percentage)} |',
  ].join('\n');
}

String renderMarkdown(CoverageSummary report, ChangedCoverage changedCoverage) {
  final changedLabel = changedCoverage.isAvailable
      ? '${changedCoverage.covered} / ${changedCoverage.total} — '
            '${formatPercentage(changedCoverage.percentage)}'
      : 'N/A — ${changedCoverage.reason}';
  final changedThresholdLabel = changedCoverage.isAvailable
      ? '${changedCoverageThreshold.toStringAsFixed(2)} % — '
            '${changedCoverage.passesThreshold ? '✅ respecté' : '❌ non atteint'}'
      : '${changedCoverageThreshold.toStringAsFixed(2)} % — ℹ️ non évalué';

  return [
    '# Couverture des tests',
    '',
    '| Indicateur | Résultat |',
    '| --- | ---: |',
    '| Couverture globale | ${report.covered} / ${report.total} — '
        '${formatPercentage(report.percentage)} |',
    '| Seuil bloquant | ${report.threshold.toStringAsFixed(2)} % — '
        '${report.passesThreshold ? '✅ respecté' : '❌ non atteint'} |',
    '| Lignes ajoutées ou modifiées | ${escapeTableCell(changedLabel)} |',
    '| Seuil différentiel | $changedThresholdLabel |',
    '',
    '## Couverture par domaine',
    '',
    '| Domaine | Lignes couvertes | Couverture |',
    '| --- | ---: | ---: |',
    for (final domain in report.domains)
      '| ${domain.name} | ${domain.covered} / ${domain.total} | '
          '${formatPercentage(domain.percentage)} |',
    '',
    '## Fichiers à 0 % (${report.zeroCoverageFiles.length})',
    '',
    filesTable(report.zeroCoverageFiles),
    '',
    '## Fichiers sous 80 % (${report.filesBelowEighty.length})',
    '',
    filesTable(report.filesBelowEighty),
    '',
    '> La couverture différentielle est bloquante lorsqu’elle est calculable.',
    '',
  ].join('\n');
}

CoverageReportResult runCoverageReport({
  required String workspace,
  String lcovPath = 'coverage/lcov.info',
  String? baseSha,
  String? headSha,
  ChangedLines? changedLines,
}) {
  final resolvedLcovPath = File(lcovPath).isAbsolute
      ? lcovPath
      : '$workspace${Platform.pathSeparator}$lcovPath';
  final files = readLcov(resolvedLcovPath);
  final summary = summarizeCoverage(files);
  final changedCoverage = summarizeChangedCoverage(
    files,
    changedLines ?? loadChangedLines(baseSha, headSha, workspace),
  );
  return CoverageReportResult(
    summary: summary,
    changedCoverage: changedCoverage,
    markdown: renderMarkdown(summary, changedCoverage),
  );
}

void appendSummary(String markdown, String? summaryPath) {
  if (summaryPath == null || summaryPath.isEmpty) {
    stdout.write(markdown);
    return;
  }
  File(summaryPath).writeAsStringSync(markdown, mode: FileMode.append);
}

int runCli(List<String> arguments, Map<String, String> environment) {
  try {
    final workspace = environment['GITHUB_WORKSPACE'] ?? Directory.current.path;
    final result = runCoverageReport(
      workspace: workspace,
      lcovPath: arguments.isEmpty ? 'coverage/lcov.info' : arguments.first,
      baseSha: environment['COVERAGE_BASE_SHA'],
      headSha: environment['COVERAGE_HEAD_SHA'],
    );
    appendSummary(result.markdown, environment['GITHUB_STEP_SUMMARY']);
    stdout.writeln(
      'Couverture globale : ${result.summary.covered} / '
      '${result.summary.total} '
      '(${formatPercentage(result.summary.percentage)}).',
    );
    var hasFailure = false;
    if (!result.summary.passesThreshold) {
      stderr.writeln(
        'La couverture globale est inférieure au seuil de '
        '${result.summary.threshold.toStringAsFixed(2)} %.',
      );
      hasFailure = true;
    }
    if (!result.changedCoverage.passesThreshold) {
      stderr.writeln(
        'La couverture différentielle est inférieure au seuil de '
        '${changedCoverageThreshold.toStringAsFixed(2)} %.',
      );
      hasFailure = true;
    }
    return hasFailure ? 1 : 0;
  } on CoverageInputException catch (error) {
    appendSummary(
      '# Couverture des tests\n\n❌ ${error.message}\n',
      environment['GITHUB_STEP_SUMMARY'],
    );
    stderr.writeln(error.message);
    return 1;
  } on Object catch (error) {
    final message = 'Calcul de couverture impossible : $error';
    appendSummary(
      '# Couverture des tests\n\n❌ $message\n',
      environment['GITHUB_STEP_SUMMARY'],
    );
    stderr.writeln(message);
    return 1;
  }
}

void main(List<String> arguments) {
  exitCode = runCli(arguments, Platform.environment);
}
