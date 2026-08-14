import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/backup_import_models.dart';
import 'package:rep_timer/models/exportable_app_settings.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/services/backup_import_exception.dart';
import 'package:rep_timer/services/backup_restore_service.dart';
import 'package:rep_timer/services/restore_key_value_store.dart';

void main() {
  test(
    'un échec intermédiaire restaure exactement toutes les valeurs brutes',
    () async {
      final original = <String, Object>{
        'trainings': 42,
        'training_history': 'private-invalid-history',
        'theme_mode': 'light',
        'prefill_exercise_name': true,
        'session_checkpoint': 'private-checkpoint',
        'internal_flag': true,
      };
      final store = _FakeRestoreStore(original, failOperations: {3});
      final service = BackupRestoreService(storeFactory: () async => store);

      await expectLater(
        service.restore(_plan()),
        throwsA(
          isA<BackupImportException>().having(
            (error) => error.kind,
            'kind',
            BackupImportFailureKind.restoreFailed,
          ),
        ),
      );

      expect(store.values, original);
    },
  );

  test('distingue explicitement un échec du rollback', () async {
    final store = _FakeRestoreStore(
      {
        'trainings': 'old-trainings',
        'training_history': 'old-history',
        'theme_mode': 'light',
      },
      failOperations: {3, 4},
    );
    final service = BackupRestoreService(storeFactory: () async => store);

    await expectLater(
      service.restore(_plan()),
      throwsA(
        isA<BackupImportException>()
            .having(
              (error) => error.kind,
              'kind',
              BackupImportFailureKind.rollbackFailed,
            )
            .having(
              (error) => error.toString(),
              'diagnostic sûr',
              isNot(contains('old-trainings')),
            ),
      ),
    );

    // Même si une clé ne peut pas être récupérée, les autres le sont encore.
    expect(store.values['training_history'], 'old-history');
    expect(store.values['theme_mode'], 'light');
    expect(store.values.containsKey('prefill_exercise_name'), isFalse);
    expect(store.values.containsKey('notification_mode'), isFalse);
  });

  test('une restauration réussie ne modifie aucune clé hors contrat', () async {
    final store = _FakeRestoreStore({
      'trainings': 'old',
      'training_history': 'old',
      'theme_mode': 'light',
      'prefill_exercise_name': true,
      'notification_mode': 'none',
      'pre_session_countdown_seconds': 9,
      'session_checkpoint': 'checkpoint',
      'internal_flag': 'unchanged',
    });

    await BackupRestoreService(
      storeFactory: () async => store,
    ).restore(_plan());

    expect(store.values['trainings'], '[]');
    expect(store.values['training_history'], '[]');
    expect(store.values['theme_mode'], 'dark');
    expect(store.values['prefill_exercise_name'], isFalse);
    expect(store.values['notification_mode'], 'sound');
    expect(store.values['pre_session_countdown_seconds'], 15);
    expect(store.values.containsKey('session_checkpoint'), isFalse);
    expect(store.values['internal_flag'], 'unchanged');
  });
}

BackupV2RestorePlan _plan() => BackupV2RestorePlan(
  exportedAt: DateTime(2026),
  trainings: const <Training>[],
  history: const <TrainingHistoryEntry>[],
  settings: const ExportableAppSettings(
    themeMode: ThemeMode.dark,
    prefillExerciseName: false,
    notificationMode: NotificationMode.sound,
    preSessionCountdownSeconds: 15,
  ),
);

class _FakeRestoreStore implements RestoreKeyValueStore {
  _FakeRestoreStore(
    Map<String, Object> initial, {
    this.failOperations = const {},
  }) : values = Map.of(initial);

  final Map<String, Object> values;
  final Set<int> failOperations;
  int _operation = 0;

  @override
  bool containsKey(String key) => values.containsKey(key);

  @override
  Object? read(String key) => values[key];

  @override
  Future<bool> remove(String key) async {
    if (_mustFail()) return false;
    values.remove(key);
    return true;
  }

  @override
  Future<bool> write(String key, Object value) async {
    if (_mustFail()) return false;
    values[key] = value;
    return true;
  }

  bool _mustFail() => failOperations.contains(++_operation);
}
