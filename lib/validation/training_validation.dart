import '../models/exercise_group.dart';
import '../models/group_type.dart';
import '../models/tabata_config.dart';
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
    groups: training.groups.map(_normalizedGroup).toList(),
  );

  /// Calcule la borne de sécurité sans développer la séance en mémoire.
  static int sessionStepUpperBound(
    Training training, {
    int stopAfter = BusinessLimits.maximumSessionSteps,
  }) {
    var total = 0;
    for (var index = 0; index < training.groups.length; index++) {
      final group = training.groups[index];
      final hasFollowingGroup = index + 1 < training.groups.length;
      if (group.type == GroupType.tabata && group.tabataConfig != null) {
        final config = group.tabataConfig!;
        final phaseCap = stopAfter + 1;
        final phases = _cappedProduct(
          _cappedProduct(config.rounds, config.exercises.length, phaseCap),
          2,
          phaseCap,
        );
        final contribution = hasFollowingGroup ? phases : phases - 1;
        if (contribution > stopAfter - total) return stopAfter + 1;
        if (contribution > 0) total += contribution;
        continue;
      }
      final rounds = group.executedRounds;
      if (rounds <= 0 || group.items.isEmpty) continue;
      var contribution = _cappedProduct(
        group.items.length,
        rounds,
        stopAfter + 1,
      );
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

  static ExerciseGroup _normalizedGroup(ExerciseGroup group) {
    final normalizedItems = group.items.map(_normalizedItem).toList();
    final config = group.tabataConfig;
    final normalizedTabata = config == null
        ? null
        : TabataConfig(
            rounds: config.rounds,
            exercises: config.exercises.map(_normalizedItem).toList(),
            restDuration: config.restDuration,
            finalRestDuration: config.finalRestDuration,
          );
    return group.copyWith(
      name: TextValidation.normalizeName(group.name),
      items: normalizedItems,
      tabataConfig: normalizedTabata,
    );
  }

  static TrainingItem _normalizedItem(TrainingItem item) => TrainingItem(
    type: item.type,
    name: item.type == ItemType.rest
        ? item.name
        : TextValidation.normalizeName(item.name),
    repetitions: item.repetitions,
    duration: item.duration,
    isFreeDuration: item.isFreeDuration,
    comment: TextValidation.normalizeComment(item.comment),
    iconName: item.iconName,
  );

  static int _cappedProduct(int left, int right, int stopAfter) {
    if (left <= 0 || right <= 0) return 0;
    if (left > stopAfter ~/ right) return stopAfter + 1;
    return left * right;
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
