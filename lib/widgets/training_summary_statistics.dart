import 'package:flutter/material.dart';

import 'statistic_badge.dart';

class TrainingSummaryStatistics extends StatelessWidget {
  const TrainingSummaryStatistics({
    super.key,
    required this.groupCount,
    required this.exerciseCount,
    required this.restCount,
  });

  final int groupCount;
  final int exerciseCount;
  final int restCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatisticBadge(
            key: const Key('summary-groups-badge'),
            icon: Icons.layers,
            label: "Groupes",
            value: "$groupCount",
            description: "Groupes : $groupCount",
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: StatisticBadge(
            key: const Key('summary-exercises-badge'),
            icon: Icons.fitness_center,
            label: "Exercices",
            value: "$exerciseCount",
            description: "Exercices : $exerciseCount",
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: StatisticBadge(
            key: const Key('summary-rests-badge'),
            icon: Icons.timer,
            label: "Pauses",
            value: "$restCount",
            description: "Pauses : $restCount",
          ),
        ),
      ],
    );
  }
}
