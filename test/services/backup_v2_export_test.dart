import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/models/history_step_entry.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/backup_export_exception.dart';
import 'package:rep_timer/services/backup_export_service.dart';
import 'package:rep_timer/services/backup_file_writer.dart';
import 'package:rep_timer/services/backup_v2_encoder.dart';
import 'package:rep_timer/services/settings_transfer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('construit l’enveloppe v2 complète avec une date injectée', () async {
    final training = _trainingWithFreeAndVariableGroups();
    final history = _legacyHistory();
    SharedPreferences.setMockInitialValues({
      'trainings': jsonEncode([training.toJson()]),
      'training_history': jsonEncode([history.toJson()]),
      'theme_mode': 'dark',
      'prefill_exercise_name': false,
      'notification_mode': 'vibration',
      'session_checkpoint': '{"private":"checkpoint"}',
      'session_notification_explanation_presented': true,
      'android_permission': 'private-permission',
    });
    final exportedAt = DateTime.parse('2026-08-05T14:23:05.123Z');

    final payload = await BackupExportService(
      now: () => exportedAt,
    ).buildPayload();
    final json = payload.toJson();
    final data = json['data'] as Map<String, dynamic>;
    final preferences = data['preferences'] as Map<String, dynamic>;

    expect(json['app'], 'RepTimer');
    expect(json['exportFormatVersion'], 2);
    expect(json['exportedAt'], exportedAt.toIso8601String());
    expect(data.keys, unorderedEquals(['trainings', 'history', 'preferences']));
    expect((data['trainings'] as List), hasLength(1));
    expect((data['history'] as List), hasLength(1));
    expect(preferences, {
      'themeMode': 'dark',
      'prefillExerciseName': false,
      'notificationMode': 'vibration',
    });

    final encoded = BackupV2Encoder.encode(payload);
    expect(encoded, contains('"exportFormatVersion": 2'));
    expect(encoded, isNot(contains('"exportFormatVersion": 1')));
    expect(encoded, isNot(contains('session_checkpoint')));
    expect(encoded, isNot(contains('session_notification_explanation')));
    expect(encoded, isNot(contains('private-permission')));
  });

  test(
    'préserve groupes libres, variables et toutes les valeurs dormantes',
    () async {
      final training = _trainingWithFreeAndVariableGroups();
      SharedPreferences.setMockInitialValues({
        'trainings': jsonEncode([training.toJson()]),
      });

      final json = (await BackupExportService().buildPayload()).toJson();
      final data = json['data'] as Map<String, dynamic>;
      final exportedTraining =
          (data['trainings'] as List).single as Map<String, dynamic>;
      final groups = exportedTraining['groups'] as List<dynamic>;
      final free = groups[0] as Map<String, dynamic>;
      final variable = groups[1] as Map<String, dynamic>;

      expect(free['type'], 'free');
      expect(free['rounds'], 2);
      expect(free['repetitionSequence'], [3, 4]);
      expect(variable['type'], 'variableRepetitions');
      expect(variable['repetitionSequence'], [8, 12, 10]);
      expect(variable['rounds'], 7);
      final variableItem =
          (variable['items'] as List).single as Map<String, dynamic>;
      expect(variableItem['repetitions'], 6);
    },
  );

  test('utilise les valeurs par défaut des préférences absentes', () async {
    final payload = await BackupExportService().buildPayload();
    final data = payload.toJson()['data'] as Map<String, dynamic>;

    expect(data['preferences'], {
      'themeMode': 'system',
      'prefillExerciseName': true,
      'notificationMode': 'none',
    });
  });

  for (final scenario
      in <
        ({
          String name,
          Map<String, Object> stored,
          BackupExportFailureKind kind,
        })
      >[
        (
          name: 'séances partielles',
          stored: {
            'trainings': jsonEncode([_validTraining().toJson(), 42]),
          },
          kind: BackupExportFailureKind.trainingsPartial,
        ),
        (
          name: 'séances illisibles',
          stored: {'trainings': 'private-invalid-trainings'},
          kind: BackupExportFailureKind.trainingsUnreadable,
        ),
        (
          name: 'historique partiel',
          stored: {
            'training_history': jsonEncode([_legacyHistory().toJson(), 42]),
          },
          kind: BackupExportFailureKind.historyPartial,
        ),
        (
          name: 'historique illisible',
          stored: {'training_history': 'private-invalid-history'},
          kind: BackupExportFailureKind.historyUnreadable,
        ),
      ]) {
    test('bloque l’export lorsque ${scenario.name}', () async {
      SharedPreferences.setMockInitialValues(scenario.stored);

      await expectLater(
        BackupExportService().buildPayload(),
        throwsA(
          isA<BackupExportException>()
              .having((error) => error.kind, 'kind', scenario.kind)
              .having(
                (error) => error.toString(),
                'diagnostic sûr',
                isNot(contains('private')),
              ),
        ),
      );
    });
  }

  test('bloque l’export si une préférence réelle est inconnue', () async {
    SharedPreferences.setMockInitialValues({'notification_mode': 'private'});

    await expectLater(
      BackupExportService().buildPayload(),
      throwsA(
        isA<BackupExportException>().having(
          (error) => error.kind,
          'kind',
          BackupExportFailureKind.preferencesUnreadable,
        ),
      ),
    );
  });

  test('bloque une séance invalide selon les règles éditoriales', () async {
    final raw = _validTraining().toJson();
    final group = (raw['groups'] as List).single as Map<String, dynamic>;
    group['rounds'] = 1000;
    SharedPreferences.setMockInitialValues({
      'trainings': jsonEncode([raw]),
    });

    await expectLater(
      BackupExportService().buildPayload(),
      throwsA(
        isA<BackupExportException>()
            .having(
              (error) => error.kind,
              'kind',
              BackupExportFailureKind.invalidTraining,
            )
            .having(
              (error) => error.userMessage,
              'message',
              allOf(contains('séance 1'), contains('groupe 1')),
            ),
      ),
    );
  });

  test('bloque un groupe variable dont la suite est invalide', () async {
    final raw = _validTraining().toJson();
    final group = (raw['groups'] as List).single as Map<String, dynamic>;
    group['type'] = 'variableRepetitions';
    group['repetitionSequence'] = [10, 0, 15];
    SharedPreferences.setMockInitialValues({
      'trainings': jsonEncode([raw]),
    });

    await expectLater(
      BackupExportService().buildPayload(),
      throwsA(
        isA<BackupExportException>()
            .having(
              (error) => error.kind,
              'kind',
              BackupExportFailureKind.invalidTraining,
            )
            .having(
              (error) => error.userMessage,
              'message',
              allOf(contains('groupe 1'), contains('tour 2')),
            ),
      ),
    );
  });

  test(
    'exporte un ancien snapshot lisible sans validation éditoriale',
    () async {
      final history = _legacyHistory();
      SharedPreferences.setMockInitialValues({
        'training_history': jsonEncode([history.toJson()]),
      });

      final payload = await BackupExportService().buildPayload();
      final data = payload.toJson()['data'] as Map<String, dynamic>;
      final exported = (data['history'] as List).single as Map<String, dynamic>;
      final step = (exported['steps'] as List).single as Map<String, dynamic>;

      expect(exported['trainingName'], history.trainingName);
      expect(step['itemName'], history.steps.single.itemName);
      expect(step['comment'], history.steps.single.comment);
    },
  );

  test(
    'écrit un fichier v2 au nom Android sûr puis le transmet au partage',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'reptimer_backup_test_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final exportedAt = DateTime.parse('2026-08-05T14:23:05.123Z');
      String? sharedPath;
      final service = SettingsTransferService(
        backupService: BackupExportService(now: () => exportedAt),
        fileWriter: BackupFileWriter(directoryProvider: () async => directory),
        shareBackup: (path) async => sharedPath = path,
      );

      await service.exportAndShare();

      expect(sharedPath, isNotNull);
      expect(
        sharedPath!.split(Platform.pathSeparator).last,
        'reptimer_backup_v2_20260805T142305123Z.json',
      );
      expect(
        sharedPath!.split(Platform.pathSeparator).last,
        matches(RegExp(r'^[A-Za-z0-9_.]+$')),
      );
      final decoded = jsonDecode(await File(sharedPath!).readAsString());
      expect((decoded as Map<String, dynamic>)['exportFormatVersion'], 2);
    },
  );

  test('convertit une erreur de fichier en erreur contrôlée', () async {
    final writer = BackupFileWriter(
      directoryProvider: () async => throw StateError('private-file-error'),
    );

    await expectLater(
      writer.write('{}', exportedAt: DateTime(2026)),
      throwsA(
        isA<BackupExportException>()
            .having(
              (error) => error.kind,
              'kind',
              BackupExportFailureKind.fileWrite,
            )
            .having(
              (error) => error.toString(),
              'diagnostic sûr',
              isNot(contains('private-file-error')),
            ),
      ),
    );
  });

  test('distingue une erreur de partage sans exposer sa cause', () async {
    final directory = await Directory.systemTemp.createTemp(
      'reptimer_backup_share_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final service = SettingsTransferService(
      fileWriter: BackupFileWriter(directoryProvider: () async => directory),
      shareBackup: (_) async => throw StateError('private-share-error'),
    );

    await expectLater(
      service.exportAndShare(),
      throwsA(
        isA<BackupExportException>()
            .having(
              (error) => error.kind,
              'kind',
              BackupExportFailureKind.share,
            )
            .having(
              (error) => error.toString(),
              'diagnostic sûr',
              isNot(contains('private-share-error')),
            ),
      ),
    );
  });
}

Training _trainingWithFreeAndVariableGroups() => Training(
  id: 'complete',
  name: 'Séance complète',
  createdAt: DateTime(2026, 8, 1),
  groups: [
    ExerciseGroup(
      id: 'free',
      name: 'Libre',
      rounds: 2,
      repetitionSequence: [3, 4],
      items: [
        TrainingItem(type: ItemType.exercise, name: 'Pompes', repetitions: 9),
      ],
    ),
    ExerciseGroup(
      id: 'variable',
      name: 'Pyramide',
      type: GroupType.variableRepetitions,
      rounds: 7,
      repetitionSequence: [8, 12, 10],
      items: [
        TrainingItem(type: ItemType.exercise, name: 'Squats', repetitions: 6),
      ],
    ),
  ],
);

Training _validTraining() => Training(
  id: 'valid',
  name: 'Valide',
  createdAt: DateTime(2026, 8, 1),
  groups: [
    ExerciseGroup(
      id: 'group',
      name: 'Groupe',
      rounds: 2,
      items: [
        TrainingItem(
          type: ItemType.exercise,
          name: 'Exercice',
          repetitions: 10,
        ),
      ],
    ),
  ],
);

TrainingHistoryEntry _legacyHistory() => TrainingHistoryEntry(
  id: 'history',
  trainingId: 'legacy',
  trainingName: 'Ancienne séance ${'x' * 80}',
  date: DateTime(2024, 1, 1),
  totalDuration: const Duration(minutes: 2),
  steps: [
    HistoryStepEntry(
      groupId: 'group',
      groupName: 'Ancien groupe ${'g' * 80}',
      itemType: ItemType.exercise,
      itemName: 'Ancien exercice ${'e' * 80}',
      repetitions: null,
      comment: 'c' * 250,
      actualDuration: const Duration(seconds: 30),
      completed: true,
    ),
  ],
);
