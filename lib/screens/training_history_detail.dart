import 'package:flutter/material.dart';

import '../models/history_step_entry.dart';
import '../models/training_history_entry.dart';
import '../models/training_item.dart';
import '../services/training_history_storage.dart';
import '../utils/formatters.dart';
import '../widgets/dialogs/confirm_dialog.dart';

/// Écran de détail d'une séance de l'historique : KPI globaux puis détail
/// par groupe (temps réellement passé sur chaque exercice/pause). Reprend
/// la présentation générale de TrainingSummaryScreen pour rester cohérent.
class TrainingHistoryDetailScreen extends StatefulWidget {
  final TrainingHistoryEntry entry;

  const TrainingHistoryDetailScreen({super.key, required this.entry});

  @override
  State<TrainingHistoryDetailScreen> createState() =>
      _TrainingHistoryDetailScreenState();
}

class _TrainingHistoryDetailScreenState
    extends State<TrainingHistoryDetailScreen> {
  // Tous les groupes sont développés par défaut ; un clic sur l'en-tête
  // d'un groupe bascule sa présence dans cet ensemble.
  final Set<String> _collapsedGroupIds = {};

  Future<void> _confirmDelete() async {
    final entry = widget.entry;

    final confirmed = await showConfirmDialog(
      context,
      title: "Supprimer cette séance ?",
      content:
          'Cette action est irréversible. Supprimer "${entry.trainingName}" de l\'historique ?',
      confirmLabel: "Supprimer",
    );

    if (!confirmed) return;

    await TrainingHistoryStorage().deleteEntry(entry.id);

    if (!mounted) return;

    // true = la séance a été supprimée, pour que l'écran Historique
    // retire cette entrée de sa liste sans avoir à tout recharger.
    Navigator.pop(context, true);
  }

  // Regroupe les étapes par groupe, en conservant l'ordre d'exécution
  // (Map préserve l'ordre d'insertion, donc l'ordre des clés reflète
  // l'ordre dans lequel chaque groupe a été rencontré en premier).
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
        .where((s) => s.itemType == ItemType.exercise)
        .toList();
    final doneExercises = exerciseSteps.where((s) => s.completed).length;

    final workDuration = steps
        .where((s) => s.itemType == ItemType.exercise)
        .fold<Duration>(Duration.zero, (sum, s) => sum + s.actualDuration);
    final restDuration = steps
        .where((s) => s.itemType == ItemType.rest)
        .fold<Duration>(Duration.zero, (sum, s) => sum + s.actualDuration);

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
              child: Text(entry.trainingName, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "Supprimer",
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.fitness_center,
                      label: "Exercices réalisés",
                      value:
                          "$doneExercises / ${exerciseSteps.length} exercices",
                    ),
                    _InfoRow(
                      icon: Icons.sports_score,
                      label: "Temps total",
                      value: formatDuration(entry.totalDuration),
                    ),
                    _InfoRow(
                      icon: Icons.directions_run,
                      label: "Temps de travail",
                      value: formatDuration(workDuration),
                    ),
                    _InfoRow(
                      icon: Icons.timer,
                      label: "Temps de pause",
                      value: formatDuration(restDuration),
                    ),
                  ],
                ),
              ),
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
                          _GroupDetailCard(
                            groupName: groupEntry.value.first.groupName,
                            steps: groupEntry.value,
                            collapsed: _collapsedGroupIds.contains(
                              groupEntry.key,
                            ),
                            onToggle: () {
                              setState(() {
                                if (!_collapsedGroupIds.add(groupEntry.key)) {
                                  _collapsedGroupIds.remove(groupEntry.key);
                                }
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

class _GroupDetailCard extends StatelessWidget {
  final String groupName;
  final List<HistoryStepEntry> steps;
  final bool collapsed;
  final VoidCallback onToggle;

  const _GroupDetailCard({
    required this.groupName,
    required this.steps,
    required this.collapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final groupTotal = steps.fold<Duration>(
      Duration.zero,
      (sum, s) => sum + s.actualDuration,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    collapsed ? Icons.expand_more : Icons.expand_less,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      groupName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formatDuration(groupTotal),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: steps
                    .map((step) => _StepDetailRow(step: step))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepDetailRow extends StatelessWidget {
  final HistoryStepEntry step;

  const _StepDetailRow({required this.step});

  @override
  Widget build(BuildContext context) {
    final firstCommentLine = step.comment?.trim().split('\n').first;
    final hasComment = firstCommentLine != null && firstCommentLine.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      step.itemType == ItemType.rest
                          ? Icons.timer
                          : Icons.fitness_center,
                      size: 16,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step.itemName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (hasComment)
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 2),
                    child: Text(
                      firstCommentLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(formatDuration(step.actualDuration)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
