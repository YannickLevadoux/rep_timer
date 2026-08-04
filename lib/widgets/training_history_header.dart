import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import 'statistic_badge.dart';

class TrainingHistoryHeader extends StatelessWidget {
  const TrainingHistoryHeader({
    super.key,
    required this.completedExerciseCount,
    required this.exerciseCount,
    required this.totalDuration,
    required this.workDuration,
    required this.restDuration,
    required this.date,
  });

  final int completedExerciseCount;
  final int exerciseCount;
  final Duration totalDuration;
  final Duration workDuration;
  final Duration restDuration;
  final DateTime date;

  static const backgroundColor = Color(0xFF111111);
  static const _foregroundColor = Colors.white;
  static const _secondaryTextColor = Color(0xFFCCCCCC);
  static const _borderColor = Color(0xFF8C8C8C);

  @override
  Widget build(BuildContext context) {
    final completedValue = "$completedExerciseCount / $exerciseCount";
    final totalValue = formatDuration(totalDuration);
    final workValue = formatDuration(workDuration);
    final restValue = formatDuration(restDuration);

    return ColoredBox(
      key: const Key('history-statistics-header'),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: StatisticBadge(
                    key: const Key('history-completed-badge'),
                    icon: Icons.check_circle_outline,
                    label: "Réalisés",
                    value: completedValue,
                    description:
                        "Exercices réalisés : $completedExerciseCount sur "
                        "$exerciseCount",
                    foregroundColor: _foregroundColor,
                    secondaryTextColor: _secondaryTextColor,
                    borderColor: _borderColor,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: StatisticBadge(
                    key: const Key('history-total-duration-badge'),
                    icon: Icons.sports_score,
                    label: "Total",
                    value: totalValue,
                    description: "Durée totale : $totalValue",
                    foregroundColor: _foregroundColor,
                    secondaryTextColor: _secondaryTextColor,
                    borderColor: _borderColor,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: StatisticBadge(
                    key: const Key('history-work-duration-badge'),
                    icon: Icons.directions_run,
                    label: "Travail",
                    value: workValue,
                    description: "Durée de travail : $workValue",
                    foregroundColor: _foregroundColor,
                    secondaryTextColor: _secondaryTextColor,
                    borderColor: _borderColor,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: StatisticBadge(
                    key: const Key('history-rest-duration-badge'),
                    icon: Icons.timer,
                    label: "Pause",
                    value: restValue,
                    description: "Durée de pause : $restValue",
                    foregroundColor: _foregroundColor,
                    secondaryTextColor: _secondaryTextColor,
                    borderColor: _borderColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatDateTime(date),
                key: const Key('history-entry-date'),
                textAlign: TextAlign.right,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: _secondaryTextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
