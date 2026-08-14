import 'package:flutter/material.dart';

import '../models/history_step_entry.dart';
import '../utils/formatters.dart';

class TrainingHistoryAmrapRows extends StatelessWidget {
  const TrainingHistoryAmrapRows({super.key, required this.step});

  final HistoryStepEntry step;

  @override
  Widget build(BuildContext context) {
    final amrap = step.amrap!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${step.itemName} · ${amrap.completedLapDurations.length} tours',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          for (
            var index = 0;
            index < amrap.completedLapDurations.length;
            index++
          )
            _LapRow(
              label: 'Tour ${index + 1}',
              duration: amrap.completedLapDurations[index],
            ),
          if (amrap.partialLapDuration != null)
            _LapRow(label: 'Tour partiel', duration: amrap.partialLapDuration!),
        ],
      ),
    );
  }
}

class _LapRow extends StatelessWidget {
  const _LapRow({required this.label, required this.duration});

  final String label;
  final Duration duration;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(formatDuration(duration)),
      ],
    ),
  );
}
