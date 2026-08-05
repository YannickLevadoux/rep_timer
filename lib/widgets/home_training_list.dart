import 'package:flutter/material.dart';

import '../models/training.dart';

/// Liste de présentation de l'accueil. La lecture, les mutations et la
/// navigation restent pilotées par l'écran parent via les callbacks.
class HomeTrainingList extends StatelessWidget {
  const HomeTrainingList({
    super.key,
    required this.trainings,
    required this.expandedTrainingId,
    required this.mutationsBlocked,
    required this.startBlocked,
    required this.onToggleExpanded,
    required this.onDuplicate,
    required this.onEdit,
    required this.onStart,
  });

  final List<Training> trainings;
  final String? expandedTrainingId;
  final bool mutationsBlocked;
  final bool startBlocked;
  final ValueChanged<String> onToggleExpanded;
  final ValueChanged<Training> onDuplicate;
  final ValueChanged<Training> onEdit;
  final ValueChanged<Training> onStart;

  @override
  Widget build(BuildContext context) {
    if (trainings.isEmpty) {
      return const Center(child: Text("Aucune séance enregistrée"));
    }

    return ListView.builder(
      itemCount: trainings.length,
      itemBuilder: (context, index) {
        final training = trainings[index];
        return _HomeTrainingCard(
          key: ValueKey(training.id),
          training: training,
          expanded: expandedTrainingId == training.id,
          mutationsBlocked: mutationsBlocked,
          startBlocked: startBlocked,
          onToggleExpanded: () => onToggleExpanded(training.id),
          onDuplicate: () => onDuplicate(training),
          onEdit: () => onEdit(training),
          onStart: () => onStart(training),
        );
      },
    );
  }
}

class _HomeTrainingCard extends StatelessWidget {
  const _HomeTrainingCard({
    super.key,
    required this.training,
    required this.expanded,
    required this.mutationsBlocked,
    required this.startBlocked,
    required this.onToggleExpanded,
    required this.onDuplicate,
    required this.onEdit,
    required this.onStart,
  });

  final Training training;
  final bool expanded;
  final bool mutationsBlocked;
  final bool startBlocked;
  final VoidCallback onToggleExpanded;
  final VoidCallback onDuplicate;
  final VoidCallback onEdit;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            title: Text(
              training.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text("${training.groups.length} groupe(s)"),
            onTap: onToggleExpanded,
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: "Dupliquer la séance",
                    onPressed: mutationsBlocked ? null : onDuplicate,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: mutationsBlocked ? null : onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text("Éditer"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: startBlocked ? null : onStart,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Commencer"),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
