import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/backup_import_models.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/exportable_app_settings.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/tabata_config.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/backup_builder.dart';
import 'package:rep_timer/services/backup_import_exception.dart';
import 'package:rep_timer/services/backup_import_parser.dart';
import 'package:rep_timer/services/backup_import_service.dart';
import 'package:rep_timer/services/json_prefs_storage.dart';
import 'package:rep_timer/services/training_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exporte et restaure sans perte un Tabata v4', () {
    final training = _training(_currentTabata());
    final payload = BackupBuilder.build(
      trainings: [training],
      history: const [],
      settings: _settings,
      exportedAt: DateTime.utc(2026),
    ).toJson();

    expect(payload['exportFormatVersion'], 4);
    final rawTraining = ((payload['data'] as Map)['trainings'] as List).single;
    final rawGroup = (rawTraining['groups'] as List).single as Map;
    expect(rawGroup['tabata']['rounds'], 2);
    expect(rawGroup['tabata']['exercises'], hasLength(2));
    expect(rawGroup.containsKey('items'), isFalse);

    final plan =
        BackupImportParser().parse(jsonEncode(payload)) as BackupRestorePlan;
    expect(plan.formatVersion, 4);
    expect(plan.trainings.single.toJson(), training.toJson());
  });

  test('restaure un Tabata v3 en conservant toutes ses données', () {
    final payload = _fullPayload(version: 3, group: _legacyTabata(cycles: 3));
    final plan =
        BackupImportParser().parse(jsonEncode(payload)) as BackupRestorePlan;
    final config = plan.trainings.single.groups.single.tabataConfig!;

    expect(config.rounds, 1);
    expect(config.exercises, hasLength(3));
    expect(config.exercises.map((item) => item.name), everyElement('Squat'));
    expect(config.exercises.map((item) => item.iconName), everyElement('star'));
    expect(
      config.exercises.map((item) => item.comment),
      everyElement('Contrôle'),
    );
    expect(config.effortDuration, const Duration(seconds: 24));
    expect(config.restDuration, const Duration(seconds: 12));
    expect(config.finalRestDuration, const Duration(seconds: 18));
  });

  test('refuse les schémas v4 incomplets, invalides et futurs', () {
    final incomplete = _currentTabata().toJson();
    (incomplete['tabata'] as Map<String, dynamic>).remove('exercises');
    final invalid = _currentTabata().toJson();
    (invalid['tabata'] as Map<String, dynamic>)['rounds'] = 100;

    for (final payload in [
      _fullPayload(version: 4, group: incomplete),
      _fullPayload(version: 4, group: invalid),
    ]) {
      expect(
        () => BackupImportParser().parse(jsonEncode(payload)),
        throwsA(isA<BackupImportException>()),
      );
    }
    expect(
      () => BackupImportParser().parse(jsonEncode(_fullPayload(version: 5))),
      throwsA(
        isA<BackupImportException>().having(
          (error) => error.kind,
          'kind',
          BackupImportFailureKind.unsupportedVersion,
        ),
      ),
    );
  });

  test(
    'une lecture locale convertit sans réécrire la valeur historique',
    () async {
      final original = jsonEncode([_trainingJson(_legacyTabata(cycles: 2))]);
      SharedPreferences.setMockInitialValues({
        TrainingStorage.storageKey: original,
      });

      final result = await TrainingStorage().loadTrainings();

      expect(result, isA<StorageReadSuccess<List<Training>>>());
      final converted =
          (result as StorageReadSuccess<List<Training>>).data.single;
      expect(converted.groups.single.tabataConfig!.exercises, hasLength(2));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(TrainingStorage.storageKey), original);
    },
  );

  test('un import v4 invalide ne mute aucune donnée locale', () async {
    const original = 'private-local-data';
    SharedPreferences.setMockInitialValues({
      TrainingStorage.storageKey: original,
    });
    final invalid = _currentTabata().toJson();
    (invalid['tabata'] as Map<String, dynamic>)['exercises'] = <dynamic>[];

    await expectLater(
      BackupImportService().importOrPrepare(
        jsonEncode(_fullPayload(version: 4, group: invalid)),
      ),
      throwsA(isA<BackupImportException>()),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(TrainingStorage.storageKey), original);
  });
}

ExerciseGroup _currentTabata() => ExerciseGroup.withTabataConfig(
  id: 'tabata',
  name: 'Tabata',
  config: TabataConfig(
    rounds: 2,
    exercises: [
      _exercise('Squat', 'star', 'Contrôle'),
      _exercise('Burpee', 'directions_run', 'Rapide'),
    ],
    restDuration: const Duration(seconds: 12),
    finalRestDuration: const Duration(seconds: 18),
  ),
);

Map<String, dynamic> _legacyTabata({required int cycles}) => {
  'id': 'tabata',
  'name': 'Tabata',
  'type': 'tabata',
  'rounds': cycles,
  'repetitionSequence': <int>[],
  'finalRestDurationSeconds': 18,
  'postGroupRestDurationSeconds': null,
  'items': [
    _exercise('Squat', 'star', 'Contrôle').toJson(),
    TrainingItem(
      type: ItemType.rest,
      name: 'Pause',
      duration: const Duration(seconds: 12),
    ).toJson(),
  ],
};

TrainingItem _exercise(String name, String icon, String comment) =>
    TrainingItem(
      type: ItemType.exercise,
      name: name,
      duration: const Duration(seconds: 24),
      iconName: icon,
      comment: comment,
    );

Training _training(ExerciseGroup group) => Training(
  id: 'training',
  name: 'Séance',
  groups: [group],
  createdAt: DateTime.utc(2026),
);

Map<String, dynamic> _trainingJson(Map<String, dynamic> group) => {
  'id': 'training',
  'name': 'Séance',
  'groups': [group],
  'createdAt': DateTime.utc(2026).toIso8601String(),
};

Map<String, dynamic> _fullPayload({
  int version = 4,
  Map<String, dynamic>? group,
}) => {
  'app': 'RepTimer',
  'exportFormatVersion': version,
  'exportedAt': DateTime.utc(2026).toIso8601String(),
  'data': {
    'trainings': group == null ? [] : [_trainingJson(group)],
    'history': [],
    'preferences': {
      'themeMode': 'system',
      'prefillExerciseName': true,
      'notificationMode': 'none',
      'preSessionCountdownSeconds': 0,
    },
  },
};

const _settings = ExportableAppSettings(
  themeMode: ThemeMode.system,
  prefillExerciseName: true,
  notificationMode: NotificationMode.none,
  preSessionCountdownSeconds: 0,
);
