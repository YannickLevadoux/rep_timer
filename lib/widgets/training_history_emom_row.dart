import 'package:flutter/material.dart';

import '../models/history_step_entry.dart';
import '../utils/formatters.dart';

class TrainingHistoryEmomRow extends StatelessWidget {
  const TrainingHistoryEmomRow({
    super.key,
    required this.step,
    required this.totalMinutes,
  });

  final HistoryStepEntry step;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    final firstCommentLine = step.comment?.trim().split('\n').first;
    final hasComment = firstCommentLine != null && firstCommentLine.isNotEmpty;
    final outline = Theme.of(context).colorScheme.outline;
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
                    Icon(Icons.fitness_center, size: 16, color: outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Minute ${step.emomMinuteIndex}/$totalMinutes · '
                        '${step.itemName}',
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
                if (hasComment)
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 2),
                    child: Text(
                      firstCommentLine,
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
}
