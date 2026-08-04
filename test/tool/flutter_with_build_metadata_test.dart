import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'le script transmet le canal DEV, un timestamp et les arguments',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'rep_timer_build_metadata_test_',
      );
      addTearDown(() => temporaryDirectory.delete(recursive: true));

      final fakeFlutter = File('${temporaryDirectory.path}/flutter');
      await fakeFlutter.writeAsString(
        '#!/usr/bin/env bash\nprintf "%s\\n" "\$@"\n',
      );
      await Process.run('chmod', ['+x', fakeFlutter.path]);

      final result = await Process.run(
        'bash',
        ['tool/flutter_with_build_metadata.sh', 'build', 'apk', '--release'],
        environment: {
          ...Platform.environment,
          'PATH': '${temporaryDirectory.path}:${Platform.environment['PATH']}',
        },
      );
      final arguments = (result.stdout as String).trim().split('\n');

      expect(result.exitCode, 0, reason: result.stderr as String?);
      expect(arguments, containsAllInOrder(['build', 'apk', '--release']));
      expect(arguments, contains('--dart-define=REP_TIMER_DISTRIBUTION=dev'));
      expect(arguments, isNot(contains(startsWith('--build-number'))));
      expect(
        arguments,
        contains(
          matches(
            RegExp(
              r'^--dart-define=REP_TIMER_BUILD_TIMESTAMP='
              r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$',
            ),
          ),
        ),
      );
    },
  );

  test(
    'le script affiche son aide sans transmettre de define à Flutter',
    () async {
      final result = await Process.run('bash', [
        'tool/flutter_with_build_metadata.sh',
        '--help',
      ]);

      expect(result.exitCode, 0);
      expect(result.stdout, contains('Usage:'));
      expect(result.stderr, isEmpty);
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
