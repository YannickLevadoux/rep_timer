import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/controllers/group_editor_controller.dart';
import 'package:rep_timer/models/backup_import_models.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/models/history_step_entry.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/backup_import_exception.dart';
import 'package:rep_timer/services/backup_import_service.dart';
import 'package:rep_timer/services/json_prefs_storage.dart';
import 'package:rep_timer/services/training_import_service.dart';
import 'package:rep_timer/services/training_history_storage.dart';
import 'package:rep_timer/services/training_storage.dart';
import 'package:rep_timer/utils/id_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'le v1 reste additif et ne touche ni historique ni préférences',
    () async {
      final local = _freeTraining(id: 'local');
      final history = _history(trainingId: 'local');
      final historyRaw = jsonEncode([history.toJson()]);
      SharedPreferences.setMockInitialValues({
        'trainings': jsonEncode([local.toJson()]),
        'training_history': historyRaw,
        'theme_mode': 'dark',
        'prefill_exercise_name': false,
        'notification_mode': 'sound',
      });
      final legacy = _freeTraining(id: 'legacy').toJson();
      final legacyGroup =
          (legacy['groups'] as List).single as Map<String, dynamic>;
      legacyGroup.remove('type');
      legacyGroup.remove('repetitionSequence');

      final result = await BackupImportService().importOrPrepare(
        jsonEncode(_v1Payload([legacy])),
      );

      expect((result as V1ImportCompleted).importedCount, 1);
      final read = await TrainingStorage().loadTrainings();
      final trainings = (read as StorageReadSuccess<List<Training>>).data;
      expect(trainings, hasLength(2));
      final imported = trainings.last;
      expect(imported.id, isNot(anyOf('local', 'legacy')));
      expect(imported.groups.single.id, isNot(legacyGroup['id']));
      expect(imported.groups.single.type, GroupType.free);
      expect(imported.groups.single.repetitionSequence, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('training_history'), historyRaw);
      expect(prefs.getString('theme_mode'), 'dark');
      expect(prefs.getBool('prefill_exercise_name'), isFalse);
      expect(prefs.getString('notification_mode'), 'sound');
    },
  );

  test('le v1 évite les identifiants locaux déjà utilisés', () async {
    final local = _freeTraining(id: 'collision-training');
    local.groups[0] = local.groups.single.copyWith(id: 'collision-group');
    SharedPreferences.setMockInitialValues({
      'trainings': jsonEncode([local.toJson()]),
    });
    final adapter = TrainingImportService(
      idGenerator: _SequenceIdGenerator([
        'collision-training',
        'new-training',
        'collision-group',
        'new-group',
      ]),
    );

    await BackupImportService(v1Adapter: adapter).importOrPrepare(
      jsonEncode(_v1Payload([_freeTraining(id: 'source').toJson()])),
    );

    final result = await TrainingStorage().loadTrainings();
    final imported = (result as StorageReadSuccess<List<Training>>).data.last;
    expect(imported.id, 'new-training');
    expect(imported.groups.single.id, 'new-group');
  });

  test('un v2 valide est résumé sans mutation avant confirmation', () async {
    final localRaw = jsonEncode([_freeTraining(id: 'local').toJson()]);
    SharedPreferences.setMockInitialValues({'trainings': localRaw});
    final exportedAt = DateTime.parse('2026-08-05T10:30:00Z');
    final payload = _v2Payload(
      trainings: [_variableTraining(id: 'restored').toJson()],
      history: [_history(trainingId: 'restored').toJson()],
      exportedAt: exportedAt,
      theme: 'dark',
      prefill: false,
      notification: 'vibration',
    );

    final outcome = await BackupImportService().importOrPrepare(
      jsonEncode(payload),
    );

    final pending = outcome as V2RestorePending;
    expect(pending.plan.exportedAt, exportedAt);
    expect(pending.plan.trainings.single.id, 'restored');
    expect(pending.plan.history.single.trainingId, 'restored');
    expect(pending.plan.settings.themeMode, ThemeMode.dark);
    expect(pending.plan.settings.prefillExerciseName, isFalse);
    expect(pending.plan.settings.notificationMode, NotificationMode.vibration);
    expect(pending.localDataWarning, isFalse);
    expect(
      (await SharedPreferences.getInstance()).getString('trainings'),
      localRaw,
    );
  });

  test(
    'confirmer un v2 remplace tout en conservant identifiants et liens',
    () async {
      SharedPreferences.setMockInitialValues({
        'trainings': jsonEncode([_freeTraining(id: 'old').toJson()]),
        'training_history': jsonEncode([_history(trainingId: 'old').toJson()]),
        'theme_mode': 'light',
        'prefill_exercise_name': true,
        'notification_mode': 'none',
        'session_checkpoint': '{"private":"old-checkpoint"}',
        'session_notification_explanation_presented': true,
        'android_permission': 'unchanged',
      });
      final service = BackupImportService();
      final pending = await service.importOrPrepare(
        jsonEncode(
          _v2Payload(
            trainings: [_variableTraining(id: 'new').toJson()],
            history: [_history(trainingId: 'new').toJson()],
            theme: 'dark',
            prefill: false,
            notification: 'sound',
          ),
        ),
      );

      await service.restoreV2((pending as V2RestorePending).plan);

      final trainings =
          (await TrainingStorage().loadTrainings()
                  as StorageReadSuccess<List<Training>>)
              .data;
      final history =
          (await TrainingHistoryStorage().loadHistory()
                  as StorageReadSuccess<List<TrainingHistoryEntry>>)
              .data;
      expect(trainings.single.id, 'new');
      expect(history.single.trainingId, 'new');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
      expect(prefs.getBool('prefill_exercise_name'), isFalse);
      expect(prefs.getString('notification_mode'), 'sound');
      expect(prefs.containsKey('session_checkpoint'), isFalse);
      expect(
        prefs.getBool('session_notification_explanation_presented'),
        isTrue,
      );
      expect(prefs.getString('android_permission'), 'unchanged');
    },
  );

  test(
    'un v2 peut remplacer un stockage local illisible après avertissement',
    () async {
      SharedPreferences.setMockInitialValues({
        'trainings': 'private-invalid-local',
        'training_history': 42,
        'theme_mode': 'private-theme',
      });
      final service = BackupImportService();
      final outcome = await service.importOrPrepare(
        jsonEncode(
          _v2Payload(trainings: [_freeTraining(id: 'healthy').toJson()]),
        ),
      );

      final pending = outcome as V2RestorePending;
      expect(pending.localDataWarning, isTrue);
      await service.restoreV2(pending.plan);

      final read = await TrainingStorage().loadTrainings();
      expect(
        (read as StorageReadSuccess<List<Training>>).data.single.id,
        'healthy',
      );
    },
  );

  for (final scenario
      in <({String name, String content, BackupImportFailureKind kind})>[
        (
          name: 'JSON invalide',
          content: 'private-invalid-json',
          kind: BackupImportFailureKind.invalidJson,
        ),
        (
          name: 'mauvaise application',
          content: '{"app":"PrivateApp","exportFormatVersion":2}',
          kind: BackupImportFailureKind.wrongApplication,
        ),
        (
          name: 'version inconnue',
          content: '{"app":"RepTimer","exportFormatVersion":4}',
          kind: BackupImportFailureKind.unsupportedVersion,
        ),
        (
          name: 'schéma incomplet',
          content: '{"app":"RepTimer","exportFormatVersion":2}',
          kind: BackupImportFailureKind.incompleteSchema,
        ),
      ]) {
    test('refuse ${scenario.name} sans aucune mutation', () async {
      const original = 'private-original-trainings';
      SharedPreferences.setMockInitialValues({'trainings': original});

      await expectLater(
        BackupImportService().importOrPrepare(scenario.content),
        throwsA(
          isA<BackupImportException>()
              .having((error) => error.kind, 'kind', scenario.kind)
              .having(
                (error) => error.toString(),
                'diagnostic sûr',
                isNot(contains('private')),
              ),
        ),
      );
      expect(
        (await SharedPreferences.getInstance()).getString('trainings'),
        original,
      );
    });
  }

  test('refuse un type de groupe v2 inconnu avant le repli tolérant', () async {
    final training = _variableTraining(id: 'unknown').toJson();
    final group = (training['groups'] as List).single as Map<String, dynamic>;
    group['type'] = 'privateFutureType';

    await expectLater(
      BackupImportService().importOrPrepare(
        jsonEncode(_v2Payload(trainings: [training])),
      ),
      throwsA(
        isA<BackupImportException>().having(
          (error) => error.kind,
          'kind',
          BackupImportFailureKind.incompatibleData,
        ),
      ),
    );
  });

  test('refuse une préférence v2 inconnue avant confirmation', () async {
    await expectLater(
      BackupImportService().importOrPrepare(
        jsonEncode(_v2Payload(theme: 'private-future-theme')),
      ),
      throwsA(
        isA<BackupImportException>().having(
          (error) => error.kind,
          'kind',
          BackupImportFailureKind.incompatibleData,
        ),
      ),
    );
  });

  test('refuse une entrée d’historique v2 invalide', () async {
    await expectLater(
      BackupImportService().importOrPrepare(
        jsonEncode(
          _v2Payload(
            history: [
              {'private': 'invalid-history'},
            ],
          ),
        ),
      ),
      throwsA(
        isA<BackupImportException>()
            .having(
              (error) => error.kind,
              'kind',
              BackupImportFailureKind.invalidHistory,
            )
            .having(
              (error) => error.toString(),
              'diagnostic sûr',
              isNot(contains('invalid-history')),
            ),
      ),
    );
  });

  for (final scenario in <({String name, List<int> sequence})>[
    (name: 'suite vide', sequence: const []),
    (name: 'valeur sous la borne', sequence: const [10, 0, 12]),
    (name: 'valeur au-dessus de la borne', sequence: const [1000]),
    (name: 'plus de 10 000 étapes', sequence: List.filled(10001, 10)),
  ]) {
    test('refuse un groupe variable avec ${scenario.name}', () async {
      final training = _variableTraining(id: 'invalid').toJson();
      final group = (training['groups'] as List).single as Map<String, dynamic>;
      group['repetitionSequence'] = scenario.sequence;

      await expectLater(
        BackupImportService().importOrPrepare(
          jsonEncode(_v2Payload(trainings: [training])),
        ),
        throwsA(
          isA<BackupImportException>().having(
            (error) => error.kind,
            'kind',
            BackupImportFailureKind.invalidTraining,
          ),
        ),
      );
    });
  }

  test('refuse aussi un nombre de tours dormant invalide', () async {
    final training = _variableTraining(id: 'invalid-rounds').toJson();
    final group = (training['groups'] as List).single as Map<String, dynamic>;
    group['rounds'] = 0;

    await expectLater(
      BackupImportService().importOrPrepare(
        jsonEncode(_v2Payload(trainings: [training])),
      ),
      throwsA(
        isA<BackupImportException>()
            .having(
              (error) => error.kind,
              'kind',
              BackupImportFailureKind.invalidTraining,
            )
            .having(
              (error) => error.userMessage,
              'emplacement utile',
              contains('groupe 1'),
            ),
      ),
    );
  });

  test('accepte une suite absente pour un groupe libre v2', () async {
    final training = _variableTraining(id: 'free-without-sequence').toJson();
    final group = (training['groups'] as List).single as Map<String, dynamic>;
    group['type'] = 'free';
    group.remove('repetitionSequence');

    final outcome = await BackupImportService().importOrPrepare(
      jsonEncode(_v2Payload(trainings: [training])),
    );

    final restoredGroup =
        (outcome as V2RestorePending).plan.trainings.single.groups.single;
    expect(restoredGroup.type, GroupType.free);
    expect(restoredGroup.repetitionSequence, isEmpty);
  });

  test('restaure le groupe variable et son aller-retour sans perte', () async {
    final service = BackupImportService();
    final pending = await service.importOrPrepare(
      jsonEncode(
        _v2Payload(trainings: [_variableTraining(id: 'variable').toJson()]),
      ),
    );
    await service.restoreV2((pending as V2RestorePending).plan);
    final read = await TrainingStorage().loadTrainings();
    final group =
        (read as StorageReadSuccess<List<Training>>).data.single.groups.single;

    expect(group.type, GroupType.variableRepetitions);
    expect(group.repetitionSequence, [8, 12, 10]);
    expect(group.rounds, 7);
    expect(group.items.single.repetitions, 6);
    final controller = GroupEditorController(group);
    addTearDown(controller.dispose);
    controller.setType(GroupType.free);
    controller.setType(GroupType.variableRepetitions);
    expect(controller.group.repetitionSequence, [8, 12, 10]);
    expect(controller.group.rounds, 7);
    expect(controller.group.items.single.repetitions, 6);
  });

  test(
    'le parcours séances refuse une sauvegarde complète sans mutation',
    () async {
      final original = jsonEncode([_freeTraining(id: 'local').toJson()]);
      SharedPreferences.setMockInitialValues({'trainings': original});

      await expectLater(
        BackupImportService().importTrainings(jsonEncode(_v2Payload())),
        throwsA(
          isA<BackupImportException>().having(
            (error) => error.kind,
            'kind',
            BackupImportFailureKind.wrongTrainingImportPath,
          ),
        ),
      );

      expect(
        (await SharedPreferences.getInstance()).getString('trainings'),
        original,
      );
    },
  );

  test('le parcours restauration refuse un export de séances', () async {
    await expectLater(
      BackupImportService().prepareRestore(
        jsonEncode(_v1Payload([_freeTraining(id: 'shared').toJson()])),
      ),
      throwsA(
        isA<BackupImportException>().having(
          (error) => error.kind,
          'kind',
          BackupImportFailureKind.wrongRestorePath,
        ),
      ),
    );
  });

  test('le parcours séances refuse un export v1 vide sans mutation', () async {
    const original = 'private-original';
    SharedPreferences.setMockInitialValues({'trainings': original});

    await expectLater(
      BackupImportService().importTrainings(jsonEncode(_v1Payload([]))),
      throwsA(
        isA<BackupImportException>().having(
          (error) => error.kind,
          'kind',
          BackupImportFailureKind.emptyTrainingExport,
        ),
      ),
    );

    expect(
      (await SharedPreferences.getInstance()).getString('trainings'),
      original,
    );
  });
}

Map<String, dynamic> _v1Payload(List<Map<String, dynamic>> trainings) => {
  'app': 'RepTimer',
  'exportFormatVersion': 1,
  'trainings': trainings,
};

Map<String, dynamic> _v2Payload({
  List<Map<String, dynamic>> trainings = const [],
  List<Map<String, dynamic>> history = const [],
  DateTime? exportedAt,
  String theme = 'system',
  bool prefill = true,
  String notification = 'none',
}) => {
  'app': 'RepTimer',
  'exportFormatVersion': 2,
  'exportedAt': (exportedAt ?? DateTime(2026, 8, 5)).toIso8601String(),
  'data': {
    'trainings': trainings,
    'history': history,
    'preferences': {
      'themeMode': theme,
      'prefillExerciseName': prefill,
      'notificationMode': notification,
    },
  },
};

Training _freeTraining({required String id}) => Training(
  id: id,
  name: 'Séance $id',
  createdAt: DateTime(2026, 8, 1),
  groups: [
    ExerciseGroup(
      id: 'group-$id',
      name: 'Libre',
      rounds: 2,
      items: [
        TrainingItem(type: ItemType.exercise, name: 'Pompes', repetitions: 10),
      ],
    ),
  ],
);

Training _variableTraining({required String id}) => Training(
  id: id,
  name: 'Séance variable',
  createdAt: DateTime(2026, 8, 1),
  groups: [
    ExerciseGroup(
      id: 'group-variable',
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

TrainingHistoryEntry _history({required String trainingId}) =>
    TrainingHistoryEntry(
      id: 'history-$trainingId',
      trainingId: trainingId,
      trainingName: 'Séance liée',
      date: DateTime(2026, 8, 2),
      totalDuration: const Duration(minutes: 1),
      steps: [
        HistoryStepEntry(
          groupId: 'group-$trainingId',
          groupName: 'Groupe',
          itemType: ItemType.exercise,
          itemName: 'Pompes',
          repetitions: 10,
          comment: null,
          actualDuration: const Duration(seconds: 30),
          completed: true,
        ),
      ],
    );

class _SequenceIdGenerator extends IdGenerator {
  _SequenceIdGenerator(this.values);

  final List<String> values;
  int _index = 0;

  @override
  String next() => values[_index++];
}
