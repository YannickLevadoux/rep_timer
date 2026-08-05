import 'package:flutter/material.dart';

import '../models/history_step_entry.dart';
import '../models/training_history_entry.dart';
import '../models/training_item.dart';
import '../services/json_prefs_storage.dart';
import '../utils/snack.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/training_history_group_card.dart';
import '../widgets/training_history_header.dart';

/// Écran de détail d'une séance de l'historique : KPI globaux puis détail
/// par groupe (temps réellement passé sur chaque exercice/pause).
class TrainingHistoryDetailScreen extends StatefulWidget {
  const TrainingHistoryDetailScreen({
    super.key,
    required this.entry,
    this.allowDelete = true,
    this.onDelete,
  });

  final TrainingHistoryEntry entry;
  final bool allowDelete;
  final Future<void> Function()? onDelete;

  @override
  State<TrainingHistoryDetailScreen> createState() =>
      _TrainingHistoryDetailScreenState();
}

class _TrainingHistoryDetailScreenState
    extends State<TrainingHistoryDetailScreen> {
  late Map<String, bool> _groupExpansion;

  @override
  void initState() {
    super.initState();
    _groupExpansion = _initialGroupExpansion(widget.entry.steps);
  }

  @override
  void didUpdateWidget(covariant TrainingHistoryDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id) {
      _groupExpansion = _initialGroupExpansion(widget.entry.steps);
    }
  }

  Map<String, bool> _initialGroupExpansion(List<HistoryStepEntry> steps) => {
    for (final step in steps) step.groupId: false,
  };

  Future<void> _confirmDelete() async {
    final entry = widget.entry;

    final bool deleted;
    try {
      deleted = await confirmAndDelete(
        context,
        title: "Supprimer cette séance ?",
        content:
            'Cette action est irréversible. Supprimer "${entry.trainingName}" de l\'historique ?',
        onDelete: widget.onDelete!,
      );
    } on StorageMutationBlockedException {
      if (!mounted) return;
      showSnack(
        context,
        "Suppression impossible : certaines données de l'historique n'ont "
        "pas pu être lues.",
      );
      return;
    }

    if (!deleted || !mounted) return;

    // true indique à l'écran Historique qu'il peut retirer l'entrée supprimée.
    Navigator.pop(context, true);
  }

  // Map préserve l'ordre de première apparition des groupes.
  Map<String, List<HistoryStepEntry>> _groupedSteps(
    List<HistoryStepEntry> steps,
  ) {
    final grouped = <String, List<HistoryStepEntry>>{};
    for (final step in steps) {
      grouped.putIfAbsent(step.groupId, () => []).add(step);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isCompleted = entry.status == TrainingSessionStatus.completed;
    final steps = entry.steps;
    final exerciseSteps = steps
        .where((step) => step.itemType == ItemType.exercise)
        .toList();
    final completedExerciseCount = exerciseSteps
        .where((step) => step.completed)
        .length;
    final workDuration = steps
        .where((step) => step.itemType == ItemType.exercise)
        .fold<Duration>(
          Duration.zero,
          (sum, step) => sum + step.actualDuration,
        );
    final restDuration = steps
        .where((step) => step.itemType == ItemType.rest)
        .fold<Duration>(
          Duration.zero,
          (sum, step) => sum + step.actualDuration,
        );
    final groupedSteps = _groupedSteps(steps);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.incomplete_circle,
              color: isCompleted
                  ? Colors.green
                  : Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.trainingName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "Supprimer",
            onPressed: widget.allowDelete && widget.onDelete != null
                ? _confirmDelete
                : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TrainingHistoryHeader(
              completedExerciseCount: completedExerciseCount,
              exerciseCount: exerciseSteps.length,
              totalDuration: entry.totalDuration,
              workDuration: workDuration,
              restDuration: restDuration,
              date: entry.date,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: steps.isEmpty
                  ? const Center(
                      child: Text(
                        "Détails non disponibles pour cette séance.",
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView(
                      children: [
                        for (final groupEntry in groupedSteps.entries)
                          TrainingHistoryGroupCard(
                            key: ValueKey(groupEntry.key),
                            groupName: groupEntry.value.first.groupName,
                            steps: groupEntry.value,
                            expanded: _groupExpansion[groupEntry.key] ?? false,
                            onToggle: () {
                              setState(() {
                                _groupExpansion[groupEntry.key] =
                                    !(_groupExpansion[groupEntry.key] ?? false);
                              });
                            },
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
