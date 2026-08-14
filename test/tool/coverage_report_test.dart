import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../.github/scripts/coverage_report.dart' as coverage;

void main() {
  String fixture(String name) {
    return File('.github/scripts/fixtures/coverage/$name').readAsStringSync();
  }

  test('produit le rapport global, par domaine et des fichiers faibles', () {
    final files = coverage.parseLcov(fixture('above-threshold.info'));
    final report = coverage.summarizeCoverage(files);

    expect(report.covered, 12);
    expect(report.total, 13);
    expect(report.percentage.toStringAsFixed(2), '92.31');
    expect(report.passesThreshold, isTrue);
    expect(report.domains.map((domain) => domain.name), [
      'models',
      'services',
      'controllers',
      'screens',
      'widgets',
      'validation',
      'utils',
      'racine de lib',
    ]);
    expect(report.zeroCoverageFiles.map((file) => file.path), [
      'lib/widgets/dialogs/untested_dialog.dart',
    ]);
    expect(report.filesBelowEighty.map((file) => file.path), [
      'lib/widgets/dialogs/untested_dialog.dart',
    ]);
  });

  test('accepte exactement la baseline globale de 91,78 %', () {
    final report = coverage.summarizeCoverage(_coverage(4589, 5000));

    expect(report.percentage, coverage.coverageThreshold);
    expect(report.passesThreshold, isTrue);
  });

  test('évalue le seuil avec la précision affichée dans le rapport', () {
    final report = coverage.summarizeCoverage(_coverage(5079, 5534));

    expect(report.percentage, lessThan(coverage.coverageThreshold));
    expect(report.percentage.toStringAsFixed(2), '91.78');
    expect(report.passesThreshold, isTrue);
  });

  test('refuse une couverture sous la baseline globale', () {
    final report = coverage.summarizeCoverage(_coverage(4588, 5000));

    expect(report.percentage, lessThan(coverage.coverageThreshold));
    expect(report.passesThreshold, isFalse);
  });

  test('refuse une entrée LCOV invalide', () {
    expect(
      () => coverage.parseLcov(fixture('invalid.info')),
      throwsA(
        isA<coverage.CoverageInputException>().having(
          (error) => error.message,
          'diagnostic',
          contains('donnée de ligne incorrecte'),
        ),
      ),
    );
  });

  test('refuse une entrée LCOV vide ou absente avec un diagnostic', () {
    expect(
      () => coverage.parseLcov('\n'),
      throwsA(
        isA<coverage.CoverageInputException>().having(
          (error) => error.message,
          'diagnostic vide',
          contains('vide'),
        ),
      ),
    );
    expect(
      () => coverage.readLcov('.github/scripts/fixtures/coverage/absent.info'),
      throwsA(
        isA<coverage.CoverageInputException>().having(
          (error) => error.message,
          'diagnostic absent',
          contains('absent'),
        ),
      ),
    );
  });

  test('calcule la couverture des lignes Dart ajoutées ou modifiées', () {
    final files = coverage.parseLcov(fixture('above-threshold.info'));
    final changedLines = coverage.parseChangedLines(
      [
        'diff --git a/lib/main.dart b/lib/main.dart',
        '+++ b/lib/main.dart',
        '@@ -0,0 +1 @@',
        '+void main() {}',
        'diff --git a/lib/widgets/dialogs/untested_dialog.dart '
            'b/lib/widgets/dialogs/untested_dialog.dart',
        '+++ b/lib/widgets/dialogs/untested_dialog.dart',
        '@@ -0,0 +1 @@',
        '+void showDialog() {}',
      ].join('\n'),
    );

    final changed = coverage.summarizeChangedCoverage(
      files,
      coverage.ChangedLines.available(changedLines),
    );

    expect(changed.isAvailable, isTrue);
    expect(changed.covered, 1);
    expect(changed.total, 2);
    expect(changed.percentage, 50);
  });

  test('retourne N/A sans ligne modifiée instrumentable', () {
    final files = coverage.parseLcov(fixture('above-threshold.info'));
    final changed = coverage.summarizeChangedCoverage(
      files,
      const coverage.ChangedLines.available({
        'lib/main.dart': {99},
      }),
    );

    expect(changed.isAvailable, isFalse);
    expect(changed.reason, contains('aucune ligne Dart instrumentable'));
    expect(changed.passesThreshold, isTrue);
  });

  test('applique le seuil différentiel de 90 % lorsqu’il est calculable', () {
    const atThreshold = coverage.ChangedCoverage.available(
      covered: 9,
      total: 10,
    );
    const belowThreshold = coverage.ChangedCoverage.available(
      covered: 8,
      total: 10,
    );

    expect(atThreshold.passesThreshold, isTrue);
    expect(belowThreshold.passesThreshold, isFalse);
  });

  test('diagnostique le contexte de pull request indisponible', () {
    final changedLines = coverage.loadChangedLines(
      null,
      null,
      Directory.current.path,
    );
    final markdown = coverage.renderMarkdown(
      coverage.summarizeCoverage(
        coverage.parseLcov(fixture('above-threshold.info')),
      ),
      coverage.ChangedCoverage.unavailable(changedLines.reason),
    );

    expect(changedLines.isAvailable, isFalse);
    expect(markdown, contains('contexte de pull request indisponible'));
    expect(markdown, contains('90.00 % — ℹ️ non évalué'));
  });

  test(
    'rend la couverture différentielle insuffisante bloquante en CLI',
    () async {
      final workspace = await Directory.systemTemp.createTemp(
        'rep_timer_coverage_diff_test_',
      );
      addTearDown(() => workspace.delete(recursive: true));
      final source = await File(
        '${workspace.path}/lib/main.dart',
      ).create(recursive: true);
      await source.writeAsString('int value = 0;\n');
      await _runGit(workspace, ['init', '-q']);
      await _runGit(workspace, ['add', '.']);
      await _commit(workspace, 'base');
      final baseSha = await _gitOutput(workspace, ['rev-parse', 'HEAD']);

      await source.writeAsString('int value = 1;\n');
      await _runGit(workspace, ['add', '.']);
      await _commit(workspace, 'head');
      final headSha = await _gitOutput(workspace, ['rev-parse', 'HEAD']);
      await File(
        '${workspace.path}/coverage.info',
      ).writeAsString(_lcov(covered: 99, total: 100, uncoveredLine: 1));
      final summary = File('${workspace.path}/summary.md');

      final exitCode = coverage.runCli(
        ['coverage.info'],
        {
          'GITHUB_WORKSPACE': workspace.path,
          'GITHUB_STEP_SUMMARY': summary.path,
          'COVERAGE_BASE_SHA': baseSha,
          'COVERAGE_HEAD_SHA': headSha,
        },
      );

      expect(exitCode, 1);
      expect(summary.readAsStringSync(), contains('0 / 1 — 0.00 %'));
      expect(summary.readAsStringSync(), contains('90.00 % — ❌ non atteint'));
    },
  );

  test('affiche les seuils globaux et différentiels', () {
    final report = coverage.summarizeCoverage(
      coverage.parseLcov(fixture('above-threshold.info')),
    );
    final markdown = coverage.renderMarkdown(
      report,
      const coverage.ChangedCoverage.available(covered: 1, total: 2),
    );

    expect(markdown, contains('92.31 %'));
    expect(markdown, contains('91.78 % — ✅ respecté'));
    expect(markdown, contains('1 / 2 — 50.00 %'));
    expect(markdown, contains('90.00 % — ❌ non atteint'));
    expect(markdown, contains('Fichiers à 0 % (1)'));
    expect(markdown, contains('Fichiers sous 80 % (1)'));
  });
}

Map<String, Map<int, int>> _coverage(int covered, int total) {
  return {
    'lib/main.dart': {
      for (var line = 1; line <= total; line++) line: line <= covered ? 1 : 0,
    },
  };
}

String _lcov({
  required int covered,
  required int total,
  required int uncoveredLine,
}) {
  return [
    'TN:',
    'SF:lib/main.dart',
    for (var line = 1; line <= total; line++)
      'DA:$line,${line == uncoveredLine || line > covered + 1 ? 0 : 1}',
    'end_of_record',
    '',
  ].join('\n');
}

Future<void> _commit(Directory directory, String message) {
  return _runGit(directory, [
    '-c',
    'user.name=RepTimer tests',
    '-c',
    'user.email=rep-timer-tests@example.com',
    'commit',
    '-qm',
    message,
  ]);
}

Future<String> _gitOutput(Directory directory, List<String> arguments) async {
  final result = await _runGit(directory, arguments);
  return result.stdout.toString().trim();
}

Future<ProcessResult> _runGit(
  Directory directory,
  List<String> arguments,
) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: directory.path,
  );
  if (result.exitCode != 0) {
    throw ProcessException(
      'git',
      arguments,
      result.stderr.toString(),
      result.exitCode,
    );
  }
  return result;
}
