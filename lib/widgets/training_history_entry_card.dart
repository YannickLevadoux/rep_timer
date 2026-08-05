import 'package:flutter/material.dart';

import '../models/training_history_entry.dart';
import '../utils/formatters.dart';

class TrainingHistoryEntryCard extends StatelessWidget {
  const TrainingHistoryEntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  final TrainingHistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isCompleted = entry.status == TrainingSessionStatus.completed;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.incomplete_circle,
                color: isCompleted
                    ? Colors.green
                    : Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.trainingName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDateTime(entry.date),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Durée : ${formatDuration(entry.totalDuration)} · "
                      "${isCompleted ? 'Terminée' : 'Incomplète'}",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: "Supprimer",
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
