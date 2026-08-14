import '../models/exercise_group.dart';
import '../models/training.dart';
import '../models/training_item.dart';
import 'exercise_group_validation.dart';
import 'text_validation.dart';
import 'validation_contract.dart';

/// Validation et normalisation de l'agrégat complet d'une séance.
abstract final class TrainingValidation {
  static List<BusinessValidationIssue> validateItem(
    TrainingItem item, {
    String? location,
  }) => ExerciseGroupValidation.validateItem(item, location: location);

  static List<BusinessValidationIssue> validateGroup(
    ExerciseGroup group, {
    String? location,
  }) => ExerciseGroupValidation.validateGroup(group, location: location);

  static List<BusinessValidationIssue> validateTraining(Training training) {
    final issues = <BusinessValidationIssue>[];
    final nameIssue = TextValidation.validateName(
      training.name,
      field: BusinessField.trainingName,
    );
    if (nameIssue != null) issues.add(nameIssue.at('séance'));
    for (var index = 0; index < training.groups.length; index++) {
      issues.addAll(
        validateGroup(training.groups[index], location: 'groupe ${index + 1}'),
      );
    }
    final stepIssue = validateSessionStepLimit(training);
    if (stepIssue != null) issues.add(stepIssue);
    return issues;
  }

  static Training normalizedTrainingCopy(Training training) => Training(
    id: training.id,
    name: TextValidation.normalizeName(training.name),
    createdAt: training.createdAt,
    groups: training.groups
        .map(
          (group) => ExerciseGroup(
            id: group.id,
            name: TextValidation.normalizeName(group.name),
            type: group.type,
            expanded: group.expanded,
            rounds: group.rounds,
            repetitionSequence: List<int>.of(group.repetitionSequence),
            finalRestDuration: group.finalRestDuration,
            postGroupRestDuration: group.postGroupRestDuration,
            items: group.items
                .map(
                  (item) => TrainingItem(
                    type: item.type,
                    name: item.type == ItemType.rest
                        ? item.name
                        : TextValidation.normalizeName(item.name),
                    repetitions: item.repetitions,
                    duration: item.duration,
                    isFreeDuration: item.isFreeDuration,
                    comment: TextValidation.normalizeComment(item.comment),
                    iconName: item.iconName,
                  ),
                )
                .toList(),
          ),
        )
        .toList(),
  );

  /// Calcule la borne de sécurité sans développer la séance en mémoire.
  static int sessionStepUpperBound(
    Training training, {
    int stopAfter = BusinessLimits.maximumSessionSteps,
  }) {
    var total = 0;
    for (var index = 0; index < training.groups.length; index++) {
      final group = training.groups[index];
      final rounds = group.executedRounds;
      if (rounds <= 0 || group.items.isEmpty) continue;
      final hasFollowingGroup = index + 1 < training.groups.length;
      var contribution = group.items.length * rounds;
      if (hasFollowingGroup && group.postGroupRestDuration != null) {
        contribution++;
      } else if (!hasFollowingGroup && group.items.last.type == ItemType.rest) {
        contribution--;
      }
      if (contribution > stopAfter - total) return stopAfter + 1;
      total += contribution;
    }
    return total;
  }

  static BusinessValidationIssue? validateSessionStepLimit(Training training) {
    final count = sessionStepUpperBound(training);
    if (count <= BusinessLimits.maximumSessionSteps) return null;
    return BusinessValidationIssue(
      field: BusinessField.sessionSteps,
      code: BusinessValidationCode.tooManySteps,
      maximum: BusinessLimits.maximumSessionSteps,
      actual: count,
      location: 'séance',
    );
  }

  static void requireValidTraining(Training training) {
    final issues = validateTraining(training);
    if (issues.isNotEmpty) throw BusinessValidationException(issues);
  }
}
