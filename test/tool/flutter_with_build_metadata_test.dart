import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String scriptPath;

  setUpAll(() {
    scriptPath = File('tool/flutter_with_build_metadata.sh').absolute.path;
  });

  test(
    'build arrête Gradle, affiche les rapports triés puis lance Flutter',
    () async {
      final fixture = await _createGitFixture();
      addTearDown(() => fixture.directory.delete(recursive: true));

      final result = await _runScript(fixture, scriptPath, [
        'build',
        'apk',
        '--release',
      ]);
      final outputLines = (result.stdout as String).trim().split('\n');
      final allFilesHeader = outputLines.indexOf(
        'Fichiers Dart suivis sous lib/ (au moins 200 lignes) :',
      );
      final addedFilesHeader = outputLines.indexOf(
        'Fichiers Dart ajoutés dans le dernier commit '
        '(au moins 200 lignes) :',
      );
      final flutterStart = outputLines.indexWhere(
        (line) => line.startsWith('FLUTTER:'),
      );

      expect(result.exitCode, 0, reason: result.stderr as String?);
      expect(outputLines.first, 'GRADLE:--stop');
      expect(outputLines.sublist(allFilesHeader + 1, addedFilesHeader), [
        '260 lib/existing.dart',
        '230 lib/added_long.dart',
        '210 lib/added_a.dart',
        '210 lib/added_z.dart',
        '200 lib/added_exact.dart',
      ]);
      expect(outputLines.sublist(addedFilesHeader + 1, flutterStart), [
        '230 lib/added_long.dart',
        '210 lib/added_a.dart',
        '210 lib/added_z.dart',
        '200 lib/added_exact.dart',
      ]);
      expect(outputLines[flutterStart], 'FLUTTER:build');
      expect(outputLines[flutterStart + 1], 'FLUTTER:apk');
      expect(outputLines, contains('FLUTTER:--release'));
      expect(
        outputLines,
        contains('FLUTTER:--dart-define=REP_TIMER_DISTRIBUTION=dev'),
      );
      expect(
        outputLines,
        contains(
          matches(
            RegExp(
              r'^FLUTTER:--dart-define=REP_TIMER_BUILD_TIMESTAMP='
              r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$',
            ),
          ),
        ),
      );
      expect(
        outputLines,
        isNot(contains(matches(RegExp(r'^FLUTTER:--build-number')))),
      );
    },
  );

  test('run effectue aussi la préparation avant Flutter', () async {
    final fixture = await _createGitFixture();
    addTearDown(() => fixture.directory.delete(recursive: true));

    final result = await _runScript(fixture, scriptPath, [
      'run',
      '-d',
      'linux',
    ]);
    final output = result.stdout as String;

    expect(result.exitCode, 0, reason: result.stderr as String?);
    expect(output, startsWith('GRADLE:--stop\n'));
    expect(
      output.indexOf('Fichiers Dart suivis sous lib/'),
      lessThan(output.indexOf('FLUTTER:run')),
    );
    expect(output, contains('FLUTTER:-d\nFLUTTER:linux'));
  });

  test('une erreur de Gradle interrompt le script', () async {
    final fixture = await _createGitFixture(gradleExitCode: 7);
    addTearDown(() => fixture.directory.delete(recursive: true));

    final result = await _runScript(fixture, scriptPath, ['build', 'apk']);
    final output = result.stdout as String;

    expect(result.exitCode, 7);
    expect(output, 'GRADLE:--stop\n');
    expect(output, isNot(contains('Fichiers Dart')));
    expect(output, isNot(contains('FLUTTER:')));
  });

  test(
    'aide et sous-commande invalide ne lancent pas la préparation',
    () async {
      final fixture = await _createGitFixture();
      addTearDown(() => fixture.directory.delete(recursive: true));

      final helpResult = await _runScript(fixture, scriptPath, ['--help']);
      final invalidResult = await _runScript(fixture, scriptPath, ['invalide']);

      expect(helpResult.exitCode, 0);
      expect(helpResult.stdout, contains('Usage:'));
      expect(helpResult.stdout, isNot(contains('GRADLE:')));
      expect(helpResult.stderr, isEmpty);
      expect(invalidResult.exitCode, 64);
      expect(invalidResult.stdout, isNot(contains('GRADLE:')));
      expect(
        invalidResult.stderr,
        contains('Sous-commande non prise en charge'),
      );
    },
  );

  test(
    'le workflow officiel transmet explicitement le canal release',
    () async {
      final workflow = await File(
        '.github/workflows/release.yml',
      ).readAsString();

      expect(
        workflow,
        contains('--dart-define=REP_TIMER_DISTRIBUTION=release'),
      );
    },
  );
}

Future<_ScriptFixture> _createGitFixture({int gradleExitCode = 0}) async {
  final directory = await Directory.systemTemp.createTemp(
    'rep_timer_build_metadata_test_',
  );
  final libDirectory = await Directory('${directory.path}/lib').create();

  await File('${libDirectory.path}/existing.dart').writeAsString(_lines(260));
  await File('${libDirectory.path}/ignored.dart').writeAsString(_lines(199));
  await _runChecked(directory, 'git', ['init', '-q']);
  await _runChecked(directory, 'git', ['add', '.']);
  await _commit(directory, 'initial');

  await File('${libDirectory.path}/added_long.dart').writeAsString(_lines(230));
  await File('${libDirectory.path}/added_a.dart').writeAsString(_lines(210));
  await File('${libDirectory.path}/added_z.dart').writeAsString(_lines(210));
  await File(
    '${libDirectory.path}/added_exact.dart',
  ).writeAsString(_lines(200));
  await File(
    '${libDirectory.path}/added_small.dart',
  ).writeAsString(_lines(199));
  await File('${libDirectory.path}/not_dart.txt').writeAsString(_lines(300));
  await _runChecked(directory, 'git', ['add', '.']);
  await _commit(directory, 'add Dart files');

  final androidDirectory = await Directory(
    '${directory.path}/android',
  ).create();
  final fakeGradle = File('${androidDirectory.path}/gradlew');
  await fakeGradle.writeAsString(
    '#!/usr/bin/env bash\n'
    'printf "GRADLE:%s\\n" "\$*"\n'
    'exit $gradleExitCode\n',
  );

  final binDirectory = await Directory('${directory.path}/bin').create();
  final fakeFlutter = File('${binDirectory.path}/flutter');
  await fakeFlutter.writeAsString(
    '#!/usr/bin/env bash\nprintf "FLUTTER:%s\\n" "\$@"\n',
  );
  await Process.run('chmod', ['+x', fakeGradle.path, fakeFlutter.path]);

  return _ScriptFixture(directory, binDirectory);
}

Future<ProcessResult> _runScript(
  _ScriptFixture fixture,
  String scriptPath,
  List<String> arguments,
) {
  return Process.run(
    'bash',
    [scriptPath, ...arguments],
    workingDirectory: fixture.directory.path,
    environment: {
      ...Platform.environment,
      'PATH': '${fixture.binDirectory.path}:${Platform.environment['PATH']}',
    },
  );
}

Future<void> _commit(Directory directory, String message) async {
  await _runChecked(directory, 'git', [
    '-c',
    'user.name=RepTimer tests',
    '-c',
    'user.email=rep-timer-tests@example.com',
    'commit',
    '-qm',
    message,
  ]);
}

Future<void> _runChecked(
  Directory directory,
  String executable,
  List<String> arguments,
) async {
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: directory.path,
  );
  if (result.exitCode != 0) {
    throw ProcessException(
      executable,
      arguments,
      result.stderr.toString(),
      result.exitCode,
    );
  }
}

String _lines(int count) => '${List.filled(count, 'line').join('\n')}\n';

class _ScriptFixture {
  const _ScriptFixture(this.directory, this.binDirectory);

  final Directory directory;
  final Directory binDirectory;
}
