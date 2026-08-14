import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/backup_import_models.dart';
import 'package:rep_timer/models/amrap_history_data.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/exportable_app_settings.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/history_step_entry.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/backup_import_exception.dart';
import 'package:rep_timer/services/backup_import_parser.dart';
import 'package:rep_timer/services/backup_builder.dart';

void main() {
  test('écrit v3 et fait un round-trip des trois nouveaux groupes', () {
    final groups = [
      ExerciseGroup.tabata(id: 'tabata')
        ..rounds = 8
        ..finalRestDuration = const Duration(seconds: 12),
      ExerciseGroup.amrap(id: 'amrap')
        ..postGroupRestDuration = const Duration(seconds: 45),
      ExerciseGroup.emom(id: 'emom')
        ..rounds = 60
        ..postGroupRestDuration = const Duration(minutes: 1),
    ];
    final payload = BackupBuilder.build(
      trainings: [_training(groups)],
      history: const [],
      settings: _settings(15),
      exportedAt: DateTime(2026),
    ).toJson();

    expect(payload['exportFormatVersion'], 3);
    final plan =
        BackupImportParser().parse(jsonEncode(payload)) as BackupV2RestorePlan;
    expect(plan.formatVersion, 3);
    expect(plan.settings.preSessionCountdownSeconds, 15);
    expect(plan.trainings.single.toJson(), _training(groups).toJson());
  });

  test('une restauration v2 utilise zéro pour le compte à rebours', () {
    final plan =
        BackupImportParser().parse(
              jsonEncode(_payload(version: 2, groups: const [])),
            )
            as BackupV2RestorePlan;

    expect(plan.formatVersion, 2);
    expect(plan.settings.preSessionCountdownSeconds, 0);
  });

  test('transporte sans perte l’historique AMRAP dans la sauvegarde', () {
    final amrap = AmrapHistoryData(
      configuredDuration: const Duration(minutes: 2),
      activeDuration: const Duration(seconds: 75),
      completedLapDurations: const [
        Duration(seconds: 30),
        Duration(seconds: 40),
      ],
      partialLapDuration: const Duration(seconds: 5),
      completed: false,
    );
    final history = TrainingHistoryEntry(
      id: 'history',
      trainingId: 'training',
      trainingName: 'Séance',
      date: DateTime(2026),
      totalDuration: const Duration(seconds: 75),
      status: TrainingSessionStatus.incomplete,
      steps: [
        HistoryStepEntry(
          groupId: 'amrap',
          groupName: 'AMRAP',
          itemType: ItemType.exercise,
          itemName: 'Effort',
          comment: null,
          actualDuration: const Duration(seconds: 75),
          completed: false,
          amrap: amrap,
        ),
      ],
    );
    final payload = BackupBuilder.build(
      trainings: const [],
      history: [history],
      settings: _settings(0),
      exportedAt: DateTime(2026),
    );

    final plan =
        BackupImportParser().parse(jsonEncode(payload.toJson()))
            as BackupV2RestorePlan;
    expect(
      plan.history.single.steps.single.amrap!.completedLapDurations,
      amrap.completedLapDurations,
    );
    expect(
      plan.history.single.steps.single.amrap!.partialLapDuration,
      const Duration(seconds: 5),
    );
  });

  test('v3 accepte 0 et 15 et refuse valeur absente, type et bornes', () {
    for (final value in [0, 15]) {
      final plan =
          BackupImportParser().parse(
                jsonEncode(_payload(version: 3, countdown: value)),
              )
              as BackupV2RestorePlan;
      expect(plan.settings.preSessionCountdownSeconds, value);
    }

    for (final value in <Object?>[null, '5', -1, 16]) {
      final payload = _payload(version: 3, countdown: value);
      if (value == null) {
        final preferences =
            (payload['data'] as Map<String, dynamic>)['preferences']
                as Map<String, dynamic>;
        preferences.remove('preSessionCountdownSeconds');
      }
      expect(
        () => BackupImportParser().parse(jsonEncode(payload)),
        throwsA(isA<BackupImportException>()),
      );
    }
  });

  test('refuse un groupe v3 incomplet ou contraire à son type', () {
    final valid = ExerciseGroup.tabata(id: 'tabata').toJson();
    final missingField = Map<String, dynamic>.of(valid)
      ..remove('finalRestDurationSeconds');
    final wrongOrder = Map<String, dynamic>.of(valid)
      ..['items'] = (valid['items'] as List<dynamic>).reversed.toList();

    for (final group in [missingField, wrongOrder]) {
      expect(
        () => BackupImportParser().parse(
          jsonEncode(_payload(version: 3, groups: [group])),
        ),
        throwsA(isA<BackupImportException>()),
      );
    }
  });

  test('refuse tout format futur avant de produire un plan', () {
    expect(
      () => BackupImportParser().parse(
        jsonEncode(_payload(version: 4, countdown: 0)),
      ),
      throwsA(
        isA<BackupImportException>().having(
          (error) => error.kind,
          'kind',
          BackupImportFailureKind.unsupportedVersion,
        ),
      ),
    );
  });
}

ExportableAppSettings _settings(int countdown) => ExportableAppSettings(
  themeMode: ThemeMode.system,
  prefillExerciseName: true,
  notificationMode: NotificationMode.none,
  preSessionCountdownSeconds: countdown,
);

Map<String, dynamic> _payload({
  required int version,
  List<Map<String, dynamic>> groups = const [],
  Object? countdown = 0,
}) => {
  'app': 'RepTimer',
  'exportFormatVersion': version,
  'exportedAt': DateTime(2026).toIso8601String(),
  'data': {
    'trainings': groups.isEmpty
        ? []
        : [
            {
              'id': 'training',
              'name': 'Séance',
              'createdAt': DateTime(2026).toIso8601String(),
              'groups': groups,
            },
          ],
    'history': [],
    'preferences': {
      'themeMode': 'system',
      'prefillExerciseName': true,
      'notificationMode': 'none',
      if (version >= 3) 'preSessionCountdownSeconds': countdown,
    },
  },
};

Training _training(List<dynamic> groups) => Training(
  id: 'training',
  name: 'Séance',
  groups: groups.map((group) {
    if (group is ExerciseGroup) return group;
    return ExerciseGroup.fromJson(group as Map<String, dynamic>);
  }).toList(),
  createdAt: DateTime(2026),
);
