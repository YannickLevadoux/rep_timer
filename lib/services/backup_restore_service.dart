import 'dart:convert';

import '../models/backup_import_models.dart';
import 'app_settings_storage.dart';
import 'backup_import_exception.dart';
import 'restore_key_value_store.dart';
import 'session_checkpoint_storage.dart';
import 'training_history_storage.dart';
import 'training_storage.dart';

typedef RestoreStoreFactory = Future<RestoreKeyValueStore> Function();

/// Remplacement transactionnel des données couvertes par une sauvegarde.
class BackupRestoreService {
  BackupRestoreService({RestoreStoreFactory? storeFactory})
    : _storeFactory = storeFactory ?? SharedPreferencesRestoreStore.create;

  final RestoreStoreFactory _storeFactory;

  static const _keys = [
    TrainingStorage.storageKey,
    TrainingHistoryStorage.storageKey,
    AppSettingsStorage.themeModeKey,
    AppSettingsStorage.prefillExerciseNameKey,
    AppSettingsStorage.notificationModeKey,
    AppSettingsStorage.preSessionCountdownSecondsKey,
    SessionCheckpointStorage.storageKey,
  ];

  Future<void> restore(BackupRestorePlan plan) async {
    final Map<String, Object?> replacements;
    try {
      replacements = {
        TrainingStorage.storageKey: jsonEncode(
          plan.trainings.map((training) => training.toJson()).toList(),
        ),
        TrainingHistoryStorage.storageKey: jsonEncode(
          plan.history.map((entry) => entry.toJson()).toList(),
        ),
        AppSettingsStorage.themeModeKey: AppSettingsStorage.serializeThemeMode(
          plan.settings.themeMode,
        ),
        AppSettingsStorage.prefillExerciseNameKey:
            plan.settings.prefillExerciseName,
        AppSettingsStorage.notificationModeKey:
            plan.settings.notificationMode.name,
        AppSettingsStorage.preSessionCountdownSecondsKey:
            plan.settings.preSessionCountdownSeconds,
        SessionCheckpointStorage.storageKey: null,
      };
    } on Object {
      throw const BackupImportException(BackupImportFailureKind.restoreFailed);
    }

    final RestoreKeyValueStore store;
    final Map<String, _StoredValue> previous;
    try {
      store = await _storeFactory();
      previous = {
        for (final key in _keys)
          key: _StoredValue(
            present: store.containsKey(key),
            value: store.read(key),
          ),
      };
    } on Object {
      throw const BackupImportException(BackupImportFailureKind.restoreFailed);
    }

    var mutationStarted = false;
    try {
      for (final key in _keys) {
        final value = replacements[key];
        final success = value == null
            ? await store.remove(key)
            : await store.write(key, value);
        if (!success) throw StateError('Écriture refusée.');
        mutationStarted = true;
      }
    } on Object {
      if (mutationStarted) {
        try {
          await _rollback(store, previous);
        } on Object {
          throw const BackupImportException(
            BackupImportFailureKind.rollbackFailed,
          );
        }
      }
      throw const BackupImportException(BackupImportFailureKind.restoreFailed);
    }
  }

  Future<void> _rollback(
    RestoreKeyValueStore store,
    Map<String, _StoredValue> previous,
  ) async {
    var failed = false;
    for (final key in _keys) {
      final oldValue = previous[key]!;
      try {
        final success = oldValue.present
            ? await store.write(key, oldValue.value!)
            : await store.remove(key);
        if (!success) failed = true;
      } on Object {
        failed = true;
      }
    }
    if (failed) throw StateError('Rollback incomplet.');
  }
}

class _StoredValue {
  const _StoredValue({required this.present, required this.value});

  final bool present;
  final Object? value;
}
