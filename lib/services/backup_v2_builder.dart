import '../models/backup_v2_payload.dart';
import '../models/training.dart';
import '../models/training_history_entry.dart';
import '../validation/business_validation.dart';
import 'app_settings_storage.dart';
import 'backup_export_exception.dart';

/// Construction pure du payload v2 à partir de données déjà lues.
abstract final class BackupV2Builder {
  static BackupV2Payload build({
    required List<Training> trainings,
    required List<TrainingHistoryEntry> history,
    required ExportableAppSettings settings,
    required DateTime exportedAt,
  }) {
    for (var index = 0; index < trainings.length; index++) {
      final issues = BusinessValidation.validateTraining(trainings[index]);
      if (issues.isNotEmpty) {
        throw BackupExportException(
          BackupExportFailureKind.invalidTraining,
          trainingIndex: index,
          issue: issues.first,
        );
      }
    }

    return BackupV2Payload(
      exportedAt: exportedAt,
      trainings: trainings.map((training) => training.toJson()).toList(),
      history: history.map((entry) => entry.toJson()).toList(),
      preferences: {
        'themeMode': AppSettingsStorage.serializeThemeMode(settings.themeMode),
        'prefillExerciseName': settings.prefillExerciseName,
        'notificationMode': settings.notificationMode.name,
      },
    );
  }
}
