import '../models/group_type.dart';
import '../models/session_step.dart';
import '../models/training.dart';
import '../models/training_item.dart';
import '../validation/business_validation.dart';

typedef TrainingSummaryCounts = ({int exercises, int total});

/// Conserve les compteurs historiques des autres groupes et utilise le plan
/// réel pour un Tabata, dont les tours ne sont pas projetés dans `items`.
TrainingSummaryCounts countTrainingSummaryItems(Training training) {
  final canDevelop =
      BusinessValidation.validateSessionStepLimit(training) == null;
  final plan = canDevelop ? buildSessionSteps(training) : const <SessionStep>[];
  var exercises = 0;
  var total = 0;
  for (final group in training.groups) {
    if (group.type == GroupType.tabata && group.tabataConfig != null) {
      final groupSteps = plan.where((step) => identical(step.group, group));
      total += groupSteps.length;
      exercises += groupSteps
          .where((step) => step.item.type == ItemType.exercise)
          .length;
      continue;
    }
    final groupTotal = group.items.length * group.executedRounds;
    total += groupTotal;
    exercises +=
        group.items.where((item) => item.type == ItemType.exercise).length *
        group.executedRounds;
  }
  return (exercises: exercises, total: total);
}
