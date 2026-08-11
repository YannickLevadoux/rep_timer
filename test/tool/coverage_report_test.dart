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

    expect(report.covered, 10);
    expect(report.total, 11);
    expect(report.percentage.toStringAsFixed(2), '90.91');
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

  test('accepte exactement le seuil global de 90,00 %', () {
    final report = coverage.summarizeCoverage(
      coverage.parseLcov(fixture('at-threshold.info')),
    );

    expect(report.percentage, 90);
    expect(report.passesThreshold, isTrue);
  });

  test('refuse une couverture sous le seuil global', () {
    final report = coverage.summarizeCoverage(
      coverage.parseLcov(fixture('below-threshold.info')),
    );

    expect(report.percentage, 80);
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
  });

  test('affiche la baseline, le seuil et la couverture différentielle', () {
    final report = coverage.summarizeCoverage(
      coverage.parseLcov(fixture('above-threshold.info')),
    );
    final markdown = coverage.renderMarkdown(
      report,
      const coverage.ChangedCoverage.available(covered: 1, total: 2),
    );

    expect(markdown, contains('90.91 %'));
    expect(markdown, contains('90.00 % — ✅ respecté'));
    expect(markdown, contains('90.38 % (+0.53 point(s))'));
    expect(markdown, contains('1 / 2 — 50.00 %'));
    expect(markdown, contains('Fichiers à 0 % (1)'));
    expect(markdown, contains('Fichiers sous 80 % (1)'));
  });
}
