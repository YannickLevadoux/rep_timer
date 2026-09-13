import 'package:flutter/material.dart';

import '../models/history_step_entry.dart';
import '../models/training_item.dart';
import '../utils/exercise_icons.dart';
import '../utils/formatters.dart';

class TrainingHistoryTabataRow extends StatelessWidget {
  const TrainingHistoryTabataRow({super.key, required this.step});

  final HistoryStepEntry step;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    final comment = step.comment?.trim().split('\n').first;
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
                          : iconForExercise(step.iconName),
                      size: 16,
                      color: outline,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_occurrenceLabel(step)} · ${step.itemName}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 2),
                  child: Text(
                    'Statut · ${step.completed ? 'Terminé' : 'Incomplet'}',
                    style: TextStyle(fontSize: 13, color: outline),
                  ),
                ),
                if (comment != null && comment.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 2),
                    child: Text(
                      comment,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: outline),
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

  String _occurrenceLabel(HistoryStepEntry step) {
    final cycle = 'Cycle ${step.tabataCycleIndex}/${step.tabataCycleTotal}';
    if (step.tabataRoundTotal == 1) return cycle;
    return 'Tour ${step.tabataRoundIndex}/${step.tabataRoundTotal} · $cycle';
  }
}
