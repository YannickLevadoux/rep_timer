import 'exercise_group.dart';
import 'session_step.dart';
import 'training.dart';
import 'training_item.dart';

/// Paramètres purs d'une séance Quick Tabata temporaire.
class QuickTabataDraft {
  const QuickTabataDraft({
    required this.name,
    required this.workDuration,
    required this.pauseDuration,
    required this.rounds,
  });

  final String name;
  final Duration workDuration;
  final Duration pauseDuration;
  final int rounds;

  Training build({DateTime? createdAt}) {
    final timestamp = createdAt ?? DateTime.now();
    final suffix = timestamp.microsecondsSinceEpoch;
    return Training(
      id: 'quick_$suffix',
      name: name,
      groups: [
        ExerciseGroup(
          id: 'quick_group_$suffix',
          name: name,
          rounds: rounds,
          items: [
            TrainingItem(
              type: ItemType.exercise,
              name: 'Work',
              duration: workDuration,
            ),
            TrainingItem(
              type: ItemType.rest,
              name: 'Pause',
              duration: pauseDuration,
            ),
          ],
        ),
      ],
      createdAt: timestamp,
    );
  }

  Duration? get estimatedDuration => estimatePlannedDuration(build());
}
