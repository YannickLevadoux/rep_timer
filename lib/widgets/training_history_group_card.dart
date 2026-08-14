import 'package:flutter/material.dart';

import '../models/history_step_entry.dart';
import '../models/training_item.dart';
import '../utils/formatters.dart';
import 'training_history_amrap_rows.dart';

class TrainingHistoryGroupCard extends StatelessWidget {
  const TrainingHistoryGroupCard({
    super.key,
    required this.groupName,
    required this.steps,
    required this.expanded,
    required this.onToggle,
  });

  final String groupName;
  final List<HistoryStepEntry> steps;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final groupTotal = steps.fold<Duration>(
      Duration.zero,
      (sum, step) => sum + step.actualDuration,
    );
    final formattedTotal = formatDuration(groupTotal);
    final expansionState = expanded ? "développé" : "replié";

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Semantics(
            container: true,
            button: true,
            expanded: expanded,
            label: "$groupName, durée $formattedTotal, groupe $expansionState",
            onTap: onToggle,
            child: ExcludeSemantics(
              child: InkWell(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
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
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            formattedTotal,
                            maxLines: 1,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  for (final step in steps) _HistoryStepRow(step: step),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryStepRow extends StatelessWidget {
  const _HistoryStepRow({required this.step});

  final HistoryStepEntry step;

  @override
  Widget build(BuildContext context) {
    final amrap = step.amrap;
    if (amrap != null) {
      return TrainingHistoryAmrapRows(step: step);
    }
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
                        _itemLabel(step),
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

  String _itemLabel(HistoryStepEntry step) {
    final minute = step.emomMinuteIndex;
    if (minute != null) return 'Minute $minute · ${step.itemName}';
    final repetitions = step.repetitions;
    if (step.itemType != ItemType.exercise || repetitions == null) {
      return step.itemName;
    }
    return '${step.itemName} × $repetitions';
  }
}
