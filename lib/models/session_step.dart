import 'exercise_group.dart';
import 'training.dart';
import 'training_item.dart';

/// Représente une occurrence unique d'un exercice ou d'une pause au sein
/// d'une séance "aplatie" : un groupe répété `rounds` fois donne autant
/// d'occurrences de chacun de ses items, dans l'ordre.
class SessionStep {
  final ExerciseGroup group;
  final int roundIndex; // 1-based : numéro du tour courant dans le groupe
  final int totalRounds;
  final TrainingItem item;

  const SessionStep({
    required this.group,
    required this.roundIndex,
    required this.totalRounds,
    required this.item,
  });
}

/// Construit la séquence complète et ordonnée des étapes d'une séance :
/// tous les items du groupe 1 répétés `rounds` fois, puis groupe 2, etc.
List<SessionStep> buildSessionSteps(Training training) {
  final steps = <SessionStep>[];

  for (final group in training.groups) {
    final rounds = group.rounds < 1 ? 1 : group.rounds;

    for (var round = 1; round <= rounds; round++) {
      for (final item in group.items) {
        steps.add(
          SessionStep(
            group: group,
            roundIndex: round,
            totalRounds: rounds,
            item: item,
          ),
        );
      }
    }
  }

  return steps;
}