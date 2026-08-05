import '../models/backup_import_models.dart';
import '../models/training.dart';
import '../models/training_history_entry.dart';
import 'app_settings_storage.dart';
import 'backup_import_parser.dart';
import 'backup_restore_service.dart';
import 'json_prefs_storage.dart';
import 'training_history_storage.dart';
import 'training_import_service.dart';
import 'training_storage.dart';

/// Coordonne l'import additif v1 et la préparation/restauration complète v2.
class BackupImportService {
  BackupImportService({
    TrainingImportService? v1Adapter,
    BackupImportParser? parser,
    BackupRestoreService? restoreService,
    TrainingStorage? trainingStorage,
    TrainingHistoryStorage? historyStorage,
    AppSettingsStorage? settingsStorage,
  }) {
    _v1Adapter = v1Adapter ?? TrainingImportService();
    _parser = parser ?? BackupImportParser(v1Adapter: _v1Adapter);
    _restoreService = restoreService ?? BackupRestoreService();
    _trainingStorage = trainingStorage ?? TrainingStorage();
    _historyStorage = historyStorage ?? TrainingHistoryStorage();
    _settingsStorage = settingsStorage ?? AppSettingsStorage();
  }

  late final TrainingImportService _v1Adapter;
  late final BackupImportParser _parser;
  late final BackupRestoreService _restoreService;
  late final TrainingStorage _trainingStorage;
  late final TrainingHistoryStorage _historyStorage;
  late final AppSettingsStorage _settingsStorage;

  Future<BackupImportOutcome> importOrPrepare(String content) async {
    final plan = _parser.parse(content);
    return switch (plan) {
      V1ImportPlan() => V1ImportCompleted(await _v1Adapter.applyV1(plan)),
      BackupV2RestorePlan() => V2RestorePending(
        plan: plan,
        localDataWarning: await _localDataNeedsWarning(),
      ),
    };
  }

  Future<void> restoreV2(BackupV2RestorePlan plan) =>
      _restoreService.restore(plan);

  Future<bool> _localDataNeedsWarning() async {
    final trainingResult = await _trainingStorage.loadTrainings();
    if (trainingResult
        case StorageReadPartial<List<Training>>() ||
            StorageReadFailure<List<Training>>()) {
      return true;
    }

    final historyResult = await _historyStorage.loadHistory();
    if (historyResult
        case StorageReadPartial<List<TrainingHistoryEntry>>() ||
            StorageReadFailure<List<TrainingHistoryEntry>>()) {
      return true;
    }

    try {
      await _settingsStorage.loadExportableSettings();
      return false;
    } on Object {
      return true;
    }
  }
}
