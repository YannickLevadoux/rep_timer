import 'package:flutter/material.dart';

import '../../models/backup_import_models.dart';

Future<bool> showRestoreBackupDialog(
  BuildContext context, {
  required BackupRestorePlan plan,
  required bool localDataWarning,
}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _RestoreBackupDialog(
          plan: plan,
          localDataWarning: localDataWarning,
        ),
      ) ??
      false;
}

class _RestoreBackupDialog extends StatelessWidget {
  const _RestoreBackupDialog({
    required this.plan,
    required this.localDataWarning,
  });

  final BackupRestorePlan plan;
  final bool localDataWarning;

  @override
  Widget build(BuildContext context) {
    final settings = plan.settings;
    final themeLabel = switch (settings.themeMode) {
      ThemeMode.system => 'Système',
      ThemeMode.light => 'Clair',
      ThemeMode.dark => 'Sombre',
    };
    final prefillLabel = settings.prefillExerciseName ? 'Activé' : 'Désactivé';

    return AlertDialog(
      title: const Text('Restaurer la sauvegarde ?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryLine(label: "Date d'export", value: _date(plan.exportedAt)),
            _SummaryLine(label: 'Séances', value: '${plan.trainings.length}'),
            _SummaryLine(label: 'Historique', value: '${plan.history.length}'),
            _SummaryLine(label: 'Thème', value: themeLabel),
            _SummaryLine(label: 'Préremplissage du nom', value: prefillLabel),
            _SummaryLine(
              label: 'Notifications',
              value: settings.notificationMode.label,
            ),
            _SummaryLine(
              label: 'Compte à rebours',
              value: settings.preSessionCountdownSeconds == 0
                  ? 'Désactivé'
                  : settings.preSessionCountdownSeconds == 1
                  ? '1 seconde'
                  : '${settings.preSessionCountdownSeconds} secondes',
            ),
            const SizedBox(height: 16),
            _DestructiveWarning(message: _replacementWarning(plan)),
            if (localDataWarning) ...[
              const SizedBox(height: 12),
              Text(
                'Certaines données actuelles sont illisibles. Continuer les '
                'remplacera définitivement par cette sauvegarde.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Restaurer'),
        ),
      ],
    );
  }

  String _date(DateTime value) {
    final date = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }
}

String _replacementWarning(BackupRestorePlan plan) {
  final trainingsEmpty = plan.trainings.isEmpty;
  final historyEmpty = plan.history.isEmpty;
  if (trainingsEmpty && historyEmpty) {
    return 'Cette sauvegarde ne contient aucune séance ni aucun historique. '
        'La restauration supprimera définitivement toutes vos séances et tout '
        'votre historique actuels, puis appliquera les préférences contenues '
        'dans le fichier.';
  }
  if (trainingsEmpty) {
    return 'Cette sauvegarde ne contient aucune séance. La restauration '
        'supprimera définitivement toutes vos séances actuelles, remplacera '
        'votre historique puis appliquera les préférences du fichier.';
  }
  if (historyEmpty) {
    return 'Cette sauvegarde ne contient aucun historique. La restauration '
        'supprimera définitivement tout votre historique actuel, remplacera '
        'vos séances puis appliquera les préférences du fichier.';
  }
  return 'Cette restauration remplacera définitivement vos séances, votre '
      'historique et vos préférences actuelles par le contenu de la '
      'sauvegarde sélectionnée.';
}

class _DestructiveWarning extends StatelessWidget {
  const _DestructiveWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Avertissement : $message',
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text('$label : $value'),
  );
}
