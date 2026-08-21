import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/backup_export_exception.dart';
import 'package:rep_timer/services/backup_file_writer.dart';
import 'package:rep_timer/services/backup_import_service.dart';
import 'package:rep_timer/services/json_prefs_storage.dart';
import 'package:rep_timer/services/training_export_service.dart';
import 'package:rep_timer/services/training_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('encode exactement la sélection v1 dans son ordre', () async {
    final first = _completeTraining('first');
    final second = _completeTraining('second');
    final exportedAt = DateTime.parse('2026-08-20T12:34:56.789Z');
    final service = TrainingExportService(now: () => exportedAt);

    final payload = service.buildSelection([second, first]);
    final decoded = jsonDecode(service.encode(payload)) as Map<String, dynamic>;

    expect(decoded.keys, [
      'app',
      'exportFormatVersion',
      'exportedAt',
      'trainings',
    ]);
    expect(decoded['app'], 'RepTimer');
    expect(decoded['exportFormatVersion'], 1);
    expect(decoded['exportedAt'], exportedAt.toIso8601String());
    final trainings = decoded['trainings'] as List<dynamic>;
    expect(trainings.map((value) => (value as Map<String, dynamic>)['id']), [
      'second',
      'first',
    ]);
    expect(decoded, isNot(contains('history')));
    expect(decoded, isNot(contains('preferences')));
    final groups = (trainings.first as Map<String, dynamic>)['groups'] as List;
    expect(groups.map((value) => (value as Map<String, dynamic>)['type']), [
      'free',
      'variableRepetitions',
      'tabata',
      'amrap',
      'emom',
    ]);
  });

  test('refuse une sélection vide', () {
    expect(
      () => TrainingExportService().buildSelection([]),
      throwsA(
        isA<BackupExportException>().having(
          (error) => error.kind,
          'kind',
          BackupExportFailureKind.emptySelection,
        ),
      ),
    );
  });

  for (final scenario in [
    (
      stored: jsonEncode([_completeTraining('valid').toJson(), 42]),
      kind: BackupExportFailureKind.trainingsPartial,
    ),
    (
      stored: 'private-invalid-json',
      kind: BackupExportFailureKind.trainingsUnreadable,
    ),
  ]) {
    test('refuse une lecture ${scenario.kind} avant présentation', () async {
      SharedPreferences.setMockInitialValues({'trainings': scenario.stored});

      await expectLater(
        TrainingExportService().loadTrainings(),
        throwsA(
          isA<BackupExportException>().having(
            (error) => error.kind,
            'kind',
            scenario.kind,
          ),
        ),
      );
    });
  }

  test('valide toute la sélection avant de produire le contenu', () {
    final invalid = _completeTraining('invalid')..name = '';

    expect(
      () => TrainingExportService().buildSelection([
        _completeTraining('valid'),
        invalid,
      ]),
      throwsA(
        isA<BackupExportException>()
            .having(
              (error) => error.kind,
              'kind',
              BackupExportFailureKind.invalidTraining,
            )
            .having((error) => error.trainingIndex, 'index', 1),
      ),
    );
  });

  test('les noms de fichiers v1 et v3 sont distincts', () {
    final date = DateTime.parse('2026-08-20T12:34:56.789Z');
    expect(
      BackupFileWriter.trainingExportFileName(date),
      'reptimer_trainings_v1_20260820T123456789Z.json',
    );
    expect(
      BackupFileWriter.trainingExportFileName(date),
      isNot(BackupFileWriter.fileName(date)),
    );
  });

  test(
    'le v1 créé est réimportable additivement avec tous les groupes',
    () async {
      final source = _completeTraining('source');
      final exporter = TrainingExportService();
      final content = exporter.encode(exporter.buildSelection([source]));

      final count = await BackupImportService().importTrainings(content);

      expect(count, 1);
      final result = await TrainingStorage().loadTrainings();
      final imported =
          (result as StorageReadSuccess<List<Training>>).data.single;
      expect(imported.id, isNot(source.id));
      expect(imported.groups.map((group) => group.type), GroupType.values);
      expect(
        imported.groups.map((group) => group.id).toSet(),
        isNot(containsAll(source.groups.map((group) => group.id))),
      );
    },
  );
}

Training _completeTraining(String id) => Training(
  id: id,
  name: 'Séance $id',
  createdAt: DateTime(2026, 8, 20),
  groups: [
    ExerciseGroup(
      id: '$id-free',
      name: 'Libre',
      items: [
        TrainingItem(type: ItemType.exercise, name: 'Pompes', repetitions: 10),
      ],
    ),
    ExerciseGroup(
      id: '$id-variable',
      name: 'Variables',
      type: GroupType.variableRepetitions,
      repetitionSequence: [5, 10, 5],
      items: [
        TrainingItem(type: ItemType.exercise, name: 'Squats', repetitions: 5),
      ],
    ),
    ExerciseGroup.tabata(id: '$id-tabata')..rounds = 4,
    ExerciseGroup.amrap(id: '$id-amrap'),
    ExerciseGroup.emom(id: '$id-emom'),
  ],
);
