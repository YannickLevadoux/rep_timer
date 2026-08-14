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
                  : '${settings.preSessionCountdownSeconds} seconde(s)',
            ),
            const SizedBox(height: 16),
            const Text(
              'Cette restauration remplacera définitivement vos séances, '
              'votre historique et vos préférences actuelles par le contenu '
              'de la sauvegarde sélectionnée.',
            ),
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
