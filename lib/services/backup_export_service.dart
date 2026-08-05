import '../models/backup_v2_payload.dart';
import '../models/training.dart';
import '../models/training_history_entry.dart';
import 'app_settings_storage.dart';
import 'backup_export_exception.dart';
import 'backup_v2_builder.dart';
import 'json_prefs_storage.dart';
import 'training_history_storage.dart';
import 'training_storage.dart';

/// Lit toutes les données exportables avant de construire la sauvegarde v2.
class BackupExportService {
  BackupExportService({
    TrainingStorage? trainingStorage,
    TrainingHistoryStorage? historyStorage,
    AppSettingsStorage? settingsStorage,
    DateTime Function()? now,
  }) : _trainingStorage = trainingStorage ?? TrainingStorage(),
       _historyStorage = historyStorage ?? TrainingHistoryStorage(),
       _settingsStorage = settingsStorage ?? AppSettingsStorage(),
       _now = now ?? DateTime.now;

  final TrainingStorage _trainingStorage;
  final TrainingHistoryStorage _historyStorage;
  final AppSettingsStorage _settingsStorage;
  final DateTime Function() _now;

  Future<BackupV2Payload> buildPayload() async {
    final trainings = _readTrainings(await _trainingStorage.loadTrainings());
    final history = _readHistory(await _historyStorage.loadHistory());
    final ExportableAppSettings settings;
    try {
      settings = await _settingsStorage.loadExportableSettings();
    } on Object {
      throw const BackupExportException(
        BackupExportFailureKind.preferencesUnreadable,
      );
    }

    return BackupV2Builder.build(
      trainings: trainings,
      history: history,
      settings: settings,
      exportedAt: _now(),
    );
  }

  List<Training> _readTrainings(
    StorageReadResult<List<Training>> result,
  ) => switch (result) {
    StorageNoData<List<Training>>() => const [],
    StorageReadSuccess<List<Training>>(:final data) => data,
    StorageReadPartial<List<Training>>() => throw const BackupExportException(
      BackupExportFailureKind.trainingsPartial,
    ),
    StorageReadFailure<List<Training>>() => throw const BackupExportException(
      BackupExportFailureKind.trainingsUnreadable,
    ),
  };

  List<TrainingHistoryEntry> _readHistory(
    StorageReadResult<List<TrainingHistoryEntry>> result,
  ) => switch (result) {
    StorageNoData<List<TrainingHistoryEntry>>() => const [],
    StorageReadSuccess<List<TrainingHistoryEntry>>(:final data) => data,
    StorageReadPartial<List<TrainingHistoryEntry>>() =>
      throw const BackupExportException(BackupExportFailureKind.historyPartial),
    StorageReadFailure<List<TrainingHistoryEntry>>() =>
      throw const BackupExportException(
        BackupExportFailureKind.historyUnreadable,
      ),
  };
}
