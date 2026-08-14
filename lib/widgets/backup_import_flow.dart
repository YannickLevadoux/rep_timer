import 'package:flutter/material.dart';

import '../models/backup_import_models.dart';
import '../services/settings_transfer_service.dart';
import '../utils/snack.dart';
import 'dialogs/restore_backup_dialog.dart';

/// Exécute le parcours UI après sélection et retourne le plan restauré afin
/// que l'écran applique immédiatement ses préférences.
Future<BackupRestorePlan?> runBackupImportFlow(
  BuildContext context,
  SettingsTransferService transferService,
) async {
  final outcome = await transferService.pickAndImport();
  if (outcome == null || !context.mounted) return null;

  switch (outcome) {
    case V1ImportCompleted(:final importedCount):
      showSnack(
        context,
        'Import terminé : $importedCount séance(s) importée(s).',
      );
      return null;
    case RestorePending(:final plan, :final localDataWarning):
      final confirmed = await showRestoreBackupDialog(
        context,
        plan: plan,
        localDataWarning: localDataWarning,
      );
      if (!confirmed) return null;

      await transferService.restoreBackup(plan);
      if (!context.mounted) return plan;
      showSnack(
        context,
        'Restauration terminée : ${plan.trainings.length} séance(s) et '
        '${plan.history.length} entrée(s) d’historique.',
      );
      return plan;
  }
}
