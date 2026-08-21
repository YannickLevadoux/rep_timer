import 'package:flutter/material.dart';

import '../models/exportable_app_settings.dart';
import '../services/backup_import_exception.dart';
import '../services/json_prefs_storage.dart';
import '../services/settings_transfer_service.dart';
import '../utils/snack.dart';
import '../widgets/contextual_help_button.dart';
import '../widgets/dialogs/restore_backup_dialog.dart';
import '../widgets/transfer_option_card.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({
    super.key,
    required this.transferService,
    required this.onSettingsRestored,
  });

  final SettingsTransferService transferService;
  final ValueChanged<ExportableAppSettings> onSettingsRestored;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _busy = false;

  Future<void> _importTrainings() async {
    await _run(() async {
      final count = await widget.transferService.pickAndImportTrainings();
      if (!mounted) return;
      if (count == null) {
        showSnack(context, 'Sélection de fichier annulée.');
        return;
      }
      showSnack(context, 'Import terminé : $count séance(s) ajoutée(s).');
      Navigator.pop(context);
    });
  }

  Future<void> _restore() async {
    await _run(() async {
      final pending = await widget.transferService.pickAndPrepareRestore();
      if (!mounted) return;
      if (pending == null) {
        showSnack(context, 'Sélection de fichier annulée.');
        return;
      }
      final confirmed = await showRestoreBackupDialog(
        context,
        plan: pending.plan,
        localDataWarning: pending.localDataWarning,
      );
      if (!confirmed || !mounted) return;
      await widget.transferService.restoreBackup(pending.plan);
      if (!mounted) return;
      widget.onSettingsRestored(pending.plan.settings);
      showSnack(
        context,
        'Restauration terminée : ${pending.plan.trainings.length} séance(s) '
        'et ${pending.plan.history.length} entrée(s) d’historique.',
      );
      Navigator.pop(context);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on BackupImportException catch (error) {
      if (mounted) showSnack(context, error.userMessage);
    } on StorageMutationBlockedException {
      if (mounted) {
        showSnack(
          context,
          "L'import est impossible car certaines séances enregistrées "
          "n'ont pas pu être lues.",
        );
      }
    } on Object {
      if (mounted) showSnack(context, "L'opération n'a pas pu être terminée.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Importer'),
        actions: const [_ImportHelpButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TransferOptionCard(
            icon: Icons.playlist_add,
            title: 'Importer des séances',
            description:
                'Ajoute les séances du fichier sans supprimer vos données locales.',
            actionLabel: 'Importer des séances',
            onPressed: _busy ? null : _importTrainings,
          ),
          TransferOptionCard(
            icon: Icons.restore,
            title: 'Restaurer les données',
            description:
                'Restaure séances, historique et préférences depuis une sauvegarde.',
            warning:
                'La restauration remplace définitivement les données locales après confirmation.',
            actionLabel: 'Restaurer les données',
            onPressed: _busy ? null : _restore,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    ),
  );
}

class _ImportHelpButton extends StatelessWidget {
  const _ImportHelpButton();

  @override
  Widget build(BuildContext context) => const ContextualHelpButton(
    title: "Aide sur l'import",
    tooltip: "Aide sur l'import",
    content: Text(
      "L'import de séances ajoute des séances sans supprimer les données locales. "
      'La restauration remplace les séances, l’historique et les préférences après confirmation. '
      'Les anciennes sauvegardes complètes restent acceptées uniquement pour la restauration.',
    ),
  );
}
