import '../models/backup_payload.dart';
import '../models/training.dart';
import '../models/training_history_entry.dart';
import 'app_settings_storage.dart';
import 'backup_builder.dart';

@Deprecated('Utiliser BackupBuilder.')
abstract final class BackupV2Builder {
  static BackupPayload build({
    required List<Training> trainings,
    required List<TrainingHistoryEntry> history,
    required ExportableAppSettings settings,
    required DateTime exportedAt,
  }) {
    return BackupBuilder.build(
      trainings: trainings,
      history: history,
      settings: settings,
      exportedAt: exportedAt,
    );
  }
}
