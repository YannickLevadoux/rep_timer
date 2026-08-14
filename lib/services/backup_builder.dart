import '../models/backup_payload.dart';
import '../models/training.dart';
import '../models/training_history_entry.dart';
import '../validation/business_validation.dart';
import 'app_settings_storage.dart';
import 'backup_export_exception.dart';
import 'pre_session_countdown_storage.dart';

/// Construction pure du payload v3 à partir de données déjà lues.
abstract final class BackupBuilder {
  static BackupPayload build({
    required List<Training> trainings,
    required List<TrainingHistoryEntry> history,
    required ExportableAppSettings settings,
    required DateTime exportedAt,
  }) {
    if (!isValidCountdownSeconds(settings.preSessionCountdownSeconds)) {
      throw const BackupExportException(
        BackupExportFailureKind.preferencesUnreadable,
      );
    }
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

    return BackupPayload(
      exportedAt: exportedAt,
      trainings: trainings.map((training) => training.toJson()).toList(),
      history: history.map((entry) => entry.toJson()).toList(),
      preferences: {
        'themeMode': AppSettingsStorage.serializeThemeMode(settings.themeMode),
        'prefillExerciseName': settings.prefillExerciseName,
        'notificationMode': settings.notificationMode.name,
        'preSessionCountdownSeconds': settings.preSessionCountdownSeconds,
      },
    );
  }
}
