import 'package:flutter/material.dart';

import '../controllers/training_history_controller.dart';
import '../models/training_history_entry.dart';
import '../services/json_prefs_storage.dart';
import '../utils/formatters.dart';
import '../utils/snack.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/storage_read_feedback.dart';
import '../widgets/training_history_content.dart';
import 'training_history_detail.dart';

/// Historique hebdomadaire. Le contrôleur injecté est possédé puis libéré par
/// cet écran ; la composition de l'application lui fournit le stockage réel.
class TrainingHistoryScreen extends StatefulWidget {
  const TrainingHistoryScreen({super.key, required this.controller});

  final TrainingHistoryController controller;

  @override
  State<TrainingHistoryScreen> createState() => _TrainingHistoryScreenState();
}

class _TrainingHistoryScreenState extends State<TrainingHistoryScreen> {
  TrainingHistoryController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(TrainingHistoryEntry entry) async {
    if (_controller.mutationsBlocked) return;

    try {
      await confirmAndDelete(
        context,
        title: "Supprimer cette séance ?",
        content:
            'Cette action est irréversible. Supprimer "${entry.trainingName}" '
            'du ${formatDateTime(entry.date)} de l\'historique ?',
        onDelete: () => _controller.deleteEntry(entry.id),
      );
    } on StorageMutationBlockedException {
      if (!mounted) return;
      showSnack(
        context,
        "Suppression impossible : certaines données de l'historique n'ont "
        "pas pu être lues.",
      );
    }
  }

  Future<void> _openDetail(TrainingHistoryEntry entry) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingHistoryDetailScreen(
          entry: entry,
          allowDelete: !_controller.mutationsBlocked,
          onDelete: () => _controller.deleteEntry(entry.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final status = _controller.status;
        return Scaffold(
          appBar: AppBar(title: const Text("Historique")),
          body: status == TrainingHistoryLoadStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : status == TrainingHistoryLoadStatus.failure
              ? StorageReadErrorView(
                  message: "L'historique enregistré n'a pas pu être lu.",
                  onRetry: _controller.load,
                )
              : TrainingHistoryContent(
                  controller: _controller,
                  storageWarning: status == TrainingHistoryLoadStatus.partial,
                  onOpenDetail: _openDetail,
                  onDelete: _confirmDelete,
                ),
        );
      },
    );
  }
}
