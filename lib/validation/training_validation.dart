import '../models/exercise_group.dart';
import '../models/group_type.dart';
import '../models/training.dart';
import '../models/training_item.dart';
import 'numeric_validation.dart';
import 'text_validation.dart';
import 'validation_contract.dart';

/// Validation et normalisation de l'agrégat complet d'une séance.
abstract final class TrainingValidation {
  static List<BusinessValidationIssue> validateItem(
    TrainingItem item, {
    String? location,
  }) {
    final issues = <BusinessValidationIssue>[];
    if (item.type == ItemType.rest) {
      final durationIssue = NumericValidation.validateDuration(item.duration);
      if (durationIssue != null) issues.add(_located(durationIssue, location));
      return issues;
    }

    final nameIssue = TextValidation.validateName(
      item.name,
      field: BusinessField.exerciseName,
    );
    if (nameIssue != null) issues.add(_located(nameIssue, location));

    final commentIssue = TextValidation.validateComment(item.comment);
    if (commentIssue != null) issues.add(_located(commentIssue, location));

    final hasRepetitions = item.repetitions != null;
    final hasDuration = item.duration != null;
    final selectedModes =
        (hasRepetitions ? 1 : 0) +
        (hasDuration ? 1 : 0) +
        (item.isFreeDuration ? 1 : 0);
    if (selectedModes != 1) {
      issues.add(
        _located(
          const BusinessValidationIssue(
            field: BusinessField.exerciseMode,
            code: BusinessValidationCode.invalidExerciseMode,
          ),
          location,
        ),
      );
      return issues;
    }
    if (hasRepetitions) {
      final repetitionsIssue = NumericValidation.validateCount(
        item.repetitions,
        field: BusinessField.repetitions,
      );
      if (repetitionsIssue != null) {
        issues.add(_located(repetitionsIssue, location));
      }
    } else if (hasDuration) {
      final durationIssue = NumericValidation.validateDuration(item.duration);
      if (durationIssue != null) issues.add(_located(durationIssue, location));
    }
    return issues;
  }

  static List<BusinessValidationIssue> validateGroup(
    ExerciseGroup group, {
    String? location,
  }) {
    final issues = <BusinessValidationIssue>[];
    final nameIssue = TextValidation.validateName(
      group.name,
      field: BusinessField.groupName,
    );
    if (nameIssue != null) issues.add(_located(nameIssue, location));
    if (group.type == GroupType.variableRepetitions) {
      if (group.repetitionSequence.isEmpty) {
        issues.add(
          _located(
            const BusinessValidationIssue(
              field: BusinessField.groupRepetitionSequence,
              code: BusinessValidationCode.required,
            ),
            location,
          ),
        );
      }
      for (var index = 0; index < group.repetitionSequence.length; index++) {
        final valueIssue = NumericValidation.validateCount(
          group.repetitionSequence[index],
          field: BusinessField.groupRepetitionValue,
        );
        if (valueIssue != null) {
          issues.add(
            _located(valueIssue, _childLocation(location, 'tour ${index + 1}')),
          );
        }
      }
    } else {
      final roundsIssue = NumericValidation.validateCount(
        group.rounds,
        field: BusinessField.groupRounds,
      );
      if (roundsIssue != null) issues.add(_located(roundsIssue, location));
    }
    for (var index = 0; index < group.items.length; index++) {
      issues.addAll(
        validateItem(
          group.items[index],
          location: _childLocation(location, 'exercice ${index + 1}'),
        ),
      );
    }
    return issues;
  }

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
    for (final group in training.groups) {
      final rounds = group.executedRounds;
      if (rounds <= 0 || group.items.isEmpty) continue;
      final remaining = stopAfter - total;
      if (rounds > remaining ~/ group.items.length) {
        return stopAfter + 1;
      }
      total += group.items.length * rounds;
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

  static BusinessValidationIssue _located(
    BusinessValidationIssue issue,
    String? location,
  ) => location == null ? issue : issue.at(location);

  static String _childLocation(String? parent, String child) =>
      parent == null ? child : '$parent, $child';
}
