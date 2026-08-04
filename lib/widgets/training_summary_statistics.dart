import 'package:flutter/material.dart';

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
          child: _StatisticBadge(
            key: const Key('summary-groups-badge'),
            icon: Icons.layers,
            label: "Groupes",
            value: groupCount,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatisticBadge(
            key: const Key('summary-exercises-badge'),
            icon: Icons.fitness_center,
            label: "Exercices",
            value: exerciseCount,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _StatisticBadge(
            key: const Key('summary-rests-badge'),
            icon: Icons.timer,
            label: "Pauses",
            value: restCount,
          ),
        ),
      ],
    );
  }
}

class _StatisticBadge extends StatelessWidget {
  const _StatisticBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final description = "$label : $value";

    return Semantics(
      container: true,
      label: description,
      excludeSemantics: true,
      child: Tooltip(
        message: description,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 5),
                      Text(
                        "$value",
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
