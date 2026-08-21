import 'package:flutter/material.dart';

import '../controllers/training_export_selection_controller.dart';
import '../services/backup_export_exception.dart';
import '../services/settings_transfer_platform.dart';
import '../services/settings_transfer_service.dart';
import '../utils/snack.dart';
import '../widgets/contextual_help_button.dart';
import '../widgets/training_export_selection.dart';
import '../widgets/transfer_option_card.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key, required this.transferService});

  final SettingsTransferService transferService;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  TrainingExportSelectionController? _selection;
  bool _loading = true;
  bool _sharing = false;
  bool _loadFailed = false;
  bool get _busy => _loading || _sharing;

  @override
  void initState() {
    super.initState();
    _loadTrainings();
  }

  @override
  void dispose() {
    _disposeSelection();
    super.dispose();
  }

  void _selectionChanged() {
    if (mounted) setState(() {});
  }

  void _disposeSelection() {
    _selection
      ?..removeListener(_selectionChanged)
      ..dispose();
  }

  Future<void> _loadTrainings() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final trainings = await widget.transferService.loadTrainingsForExport();
      if (!mounted) return;
      _disposeSelection();
      final selection = TrainingExportSelectionController(trainings)
        ..addListener(_selectionChanged);
      setState(() => _selection = selection);
    } on BackupExportException catch (error) {
      if (mounted) showSnack(context, error.userMessage);
      _loadFailed = true;
    } on Object {
      if (mounted) {
        showSnack(context, "Les séances n'ont pas pu être chargées.");
      }
      _loadFailed = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _share(
    Future<TransferShareResult> Function() startOperation,
  ) async {
    if (_busy) return;
    setState(() => _sharing = true);
    try {
      final result = await startOperation();
      if (!mounted) return;
      if (result == TransferShareResult.dismissed) {
        showSnack(context, 'Partage annulé.');
        return;
      }
      showSnack(context, 'Fichier confié à la feuille de partage.');
      Navigator.pop(context);
    } on BackupExportException catch (error) {
      if (mounted) showSnack(context, error.userMessage);
    } on Object {
      if (mounted) showSnack(context, "Le fichier n'a pas pu être partagé.");
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = _selection;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Exporter'),
          actions: const [_ExportHelpButton()],
        ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            TransferOptionCard(
              icon: Icons.fitness_center,
              title: 'Exporter des séances',
              description:
                  'Partage une sélection de séances sans historique ni préférences.',
              actionLabel: 'Exporter',
              onPressed: !_busy && (selection?.hasSelection ?? false)
                  ? () => _share(
                      () => widget.transferService.exportTrainingsAndShare(
                        selection!.selectedTrainings,
                      ),
                    )
                  : null,
              child: _trainingContent(selection),
            ),
            TransferOptionCard(
              icon: Icons.backup_outlined,
              title: 'Sauvegarder les données',
              description:
                  'Partage une sauvegarde complète avec séances, historique et préférences.',
              actionLabel: 'Sauvegarder les données',
              onPressed: _busy
                  ? null
                  : () => _share(widget.transferService.exportAndShare),
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

  Widget _trainingContent(TrainingExportSelectionController? selection) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadFailed) {
      return OutlinedButton(
        onPressed: _loadTrainings,
        child: const Text('Réessayer'),
      );
    }
    if (selection == null || selection.trainings.isEmpty) {
      return const Text('Aucune séance enregistrée à exporter.');
    }
    return TrainingExportSelection(controller: selection, enabled: !_busy);
  }
}

class _ExportHelpButton extends StatelessWidget {
  const _ExportHelpButton();

  @override
  Widget build(BuildContext context) => const ContextualHelpButton(
    title: "Aide sur l'export",
    tooltip: "Aide sur l'export",
    content: Text(
      "L'export de séances sert au partage et ne contient que les séances choisies. "
      'La sauvegarde complète contient aussi l’historique et les préférences. '
      'RepTimer crée toujours le format actuel de sauvegarde complète.',
    ),
  );
}
