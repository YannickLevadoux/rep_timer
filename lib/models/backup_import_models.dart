import 'package:flutter/material.dart';

import 'exportable_app_settings.dart';
import 'training.dart';
import 'training_history_entry.dart';

sealed class BackupImportOutcome {
  const BackupImportOutcome();
}

sealed class BackupImportPlan {
  const BackupImportPlan();
}

final class V1ImportCompleted extends BackupImportOutcome {
  const V1ImportCompleted(this.importedCount);

  final int importedCount;
}

final class V2RestorePending extends BackupImportOutcome {
  const V2RestorePending({required this.plan, required this.localDataWarning});

  final BackupV2RestorePlan plan;
  final bool localDataWarning;
}

/// Données v2 entièrement décodées et validées, prêtes à être restaurées.
@immutable
class BackupV2RestorePlan extends BackupImportPlan {
  const BackupV2RestorePlan({
    required this.exportedAt,
    required this.trainings,
    required this.history,
    required this.settings,
  });

  final DateTime exportedAt;
  final List<Training> trainings;
  final List<TrainingHistoryEntry> history;
  final ExportableAppSettings settings;
}

@immutable
class V1ImportPlan extends BackupImportPlan {
  const V1ImportPlan(this.trainings);

  final List<Training> trainings;
}
