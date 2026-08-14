import 'exercise_group.dart';
import 'group_type.dart';
import 'training.dart';
import 'training_item.dart';
import '../validation/business_validation.dart';

/// Représente une occurrence unique d'un exercice ou d'une pause au sein
/// d'une séance "aplatie" : un groupe répété `rounds` fois donne autant
/// d'occurrences de chacun de ses items, dans l'ordre.
class SessionStep {
  final ExerciseGroup group;
  final int roundIndex; // 1-based : numéro du tour courant dans le groupe
  final int totalRounds;
  final TrainingItem item;

  /// Élément du modèle édité à l'origine de cette étape. Pour un exercice à
  /// répétitions variables, [item] est une copie portant la valeur résolue du
  /// tour tandis que [sourceItem] reste l'objet à persister (commentaire,
  /// réglages...). Pour les autres étapes, les deux références sont identiques.
  final TrainingItem sourceItem;

  const SessionStep({
    required this.group,
    required this.roundIndex,
    required this.totalRounds,
    required this.item,
    TrainingItem? sourceItem,
  }) : sourceItem = sourceItem ?? item;
}

/// Construit la séquence complète et ordonnée des étapes d'une séance :
/// tous les items du groupe 1 répétés `rounds` fois, puis groupe 2, etc.
List<SessionStep> buildSessionSteps(Training training) {
  final limitIssue = BusinessValidation.validateSessionStepLimit(training);
  if (limitIssue != null) {
    throw BusinessValidationException([limitIssue]);
  }
  final steps = <SessionStep>[];

  for (var groupIndex = 0; groupIndex < training.groups.length; groupIndex++) {
    final group = training.groups[groupIndex];
    final rounds = group.executedRounds;

    for (var round = 1; round <= rounds; round++) {
      for (final item in group.items) {
        final resolvedItem =
            group.type == GroupType.variableRepetitions &&
                item.type == ItemType.exercise &&
                item.repetitions != null
            ? item.copyWith(repetitions: group.repetitionSequence[round - 1])
            : item;
        steps.add(
          SessionStep(
            group: group,
            roundIndex: round,
            totalRounds: rounds,
            item: resolvedItem,
            sourceItem: item,
          ),
        );
      }
    }

    final hasFollowingGroup = groupIndex + 1 < training.groups.length;
    if (hasFollowingGroup &&
        group.type == GroupType.tabata &&
        group.finalRestDuration != null &&
        steps.isNotEmpty &&
        steps.last.group == group &&
        steps.last.item.type == ItemType.rest) {
      final last = steps.removeLast();
      final finalRest = last.item.copyWith(duration: group.finalRestDuration);
      steps.add(
        SessionStep(
          group: group,
          roundIndex: last.roundIndex,
          totalRounds: last.totalRounds,
          item: finalRest,
          sourceItem: last.sourceItem,
        ),
      );
    }
    if (hasFollowingGroup && group.postGroupRestDuration != null) {
      final rest = TrainingItem(
        type: ItemType.rest,
        name: 'Pause',
        duration: group.postGroupRestDuration,
      );
      steps.add(
        SessionStep(
          group: group,
          roundIndex: rounds,
          totalRounds: rounds,
          item: rest,
        ),
      );
    }
  }

  // Si la toute dernière étape de la séance (dernier groupe, dernier tour,
  // dernier item) est une pause, on l'ignore : la séance doit se terminer
  // immédiatement après le dernier exercice, pas sur une pause inutile.
  // Ne concerne que cette pause finale précise ; toutes les autres pauses
  // (entre exercices, entre tours, entre groupes) restent inchangées.
  if (steps.isNotEmpty && steps.last.item.type == ItemType.rest) {
    steps.removeLast();
  }

  return steps;
}

/// Calcule la durée programmée d'une séance à partir de la séquence exacte
/// produite par [buildSessionSteps].
///
/// Une séance vide a une durée programmée nulle. En revanche, dès qu'une
/// étape n'a pas de durée fixe, la durée complète ne peut pas être estimée et
/// la fonction retourne `null`.
Duration? estimatePlannedDuration(Training training) {
  var total = Duration.zero;

  for (final step in buildSessionSteps(training)) {
    final duration = step.item.duration;
    if (duration == null) return null;
    total += duration;
  }

  return total;
}
