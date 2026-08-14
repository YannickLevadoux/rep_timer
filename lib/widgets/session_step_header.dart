import 'package:flutter/material.dart';

import '../models/group_type.dart';
import '../models/session_step.dart';
import '../models/training_item.dart';
import '../utils/exercise_icons.dart';

class SessionStepMetadata extends StatelessWidget {
  const SessionStepMetadata({super.key, required this.step});

  final SessionStep step;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          step.group.name,
          key: const Key('current-group-name'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      const SizedBox(width: 12),
      if (step.group.type != GroupType.amrap)
        Text(
          _progressLabel,
          key: const Key('round-label'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
    ],
  );

  String get _progressLabel => switch (step.group.type) {
    GroupType.tabata => 'Cycle ${step.roundIndex}/${step.totalRounds}',
    GroupType.emom => 'Minute ${step.roundIndex}/${step.totalRounds}',
    _ => 'Tour ${step.roundIndex}/${step.totalRounds}',
  };
}

class SessionStepIdentity extends StatelessWidget {
  const SessionStepIdentity({
    super.key,
    required this.item,
    required this.blinkOpacity,
  });

  final TrainingItem item;
  final Animation<double> blinkOpacity;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: blinkOpacity,
      child: Column(
        children: [
          Icon(
            item.type == ItemType.exercise
                ? iconForExercise(item.iconName)
                : Icons.timer,
            key: const Key('current-step-icon'),
            size: 48,
            color: colors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            key: const Key('current-step-name'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
