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

final class RestorePending extends BackupImportOutcome {
  const RestorePending({required this.plan, required this.localDataWarning});

  final BackupRestorePlan plan;
  final bool localDataWarning;
}

/// Données v2 ou v3 entièrement décodées et validées avant restauration.
@immutable
class BackupRestorePlan extends BackupImportPlan {
  const BackupRestorePlan({
    required this.exportedAt,
    required this.trainings,
    required this.history,
    required this.settings,
    this.formatVersion = 2,
  });

  final DateTime exportedAt;
  final List<Training> trainings;
  final List<TrainingHistoryEntry> history;
  final ExportableAppSettings settings;
  final int formatVersion;
}

typedef V2RestorePending = RestorePending;
typedef BackupV2RestorePlan = BackupRestorePlan;

@immutable
class V1ImportPlan extends BackupImportPlan {
  const V1ImportPlan(this.trainings);

  final List<Training> trainings;
}
