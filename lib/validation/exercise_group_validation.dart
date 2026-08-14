import '../models/exercise_group.dart';
import '../models/group_type.dart';
import '../models/training_item.dart';
import 'numeric_validation.dart';
import 'text_validation.dart';
import 'timed_group_validation.dart';
import 'validation_contract.dart';

/// Validation métier des exercices et des groupes, sans orchestration de la
/// séance complète ni calcul de sa taille développée.
abstract final class ExerciseGroupValidation {
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

    final modeIssue = hasRepetitions
        ? NumericValidation.validateCount(
            item.repetitions,
            field: BusinessField.repetitions,
          )
        : hasDuration
        ? NumericValidation.validateDuration(item.duration)
        : null;
    if (modeIssue != null) issues.add(_located(modeIssue, location));
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
    issues.addAll(_validateType(group, location));

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

  static List<BusinessValidationIssue> _validateType(
    ExerciseGroup group,
    String? location,
  ) {
    return switch (group.type) {
      GroupType.free => _validateFree(group, location),
      GroupType.variableRepetitions => _validateVariable(group, location),
      GroupType.tabata || GroupType.amrap || GroupType.emom =>
        TimedGroupValidation.validate(group, location: location),
    };
  }

  static List<BusinessValidationIssue> _validateFree(
    ExerciseGroup group,
    String? location,
  ) {
    if (group.finalRestDuration != null ||
        group.postGroupRestDuration != null) {
      return [
        _located(
          const BusinessValidationIssue(
            field: BusinessField.groupStructure,
            code: BusinessValidationCode.invalidGroupStructure,
          ),
          location,
        ),
      ];
    }
    final issue = NumericValidation.validateCount(
      group.rounds,
      field: BusinessField.groupRounds,
    );
    return issue == null ? const [] : [_located(issue, location)];
  }

  static List<BusinessValidationIssue> _validateVariable(
    ExerciseGroup group,
    String? location,
  ) {
    if (group.finalRestDuration != null ||
        group.postGroupRestDuration != null) {
      return [
        _located(
          const BusinessValidationIssue(
            field: BusinessField.groupStructure,
            code: BusinessValidationCode.invalidGroupStructure,
          ),
          location,
        ),
      ];
    }

    if (group.repetitionSequence.isEmpty) {
      return [
        _located(
          const BusinessValidationIssue(
            field: BusinessField.groupRepetitionSequence,
            code: BusinessValidationCode.required,
          ),
          location,
        ),
      ];
    }

    final issues = <BusinessValidationIssue>[];
    for (var index = 0; index < group.repetitionSequence.length; index++) {
      final issue = NumericValidation.validateCount(
        group.repetitionSequence[index],
        field: BusinessField.groupRepetitionValue,
      );
      if (issue != null) {
        issues.add(
          _located(issue, _childLocation(location, 'tour ${index + 1}')),
        );
      }
    }
    return issues;
  }

  static BusinessValidationIssue _located(
    BusinessValidationIssue issue,
    String? location,
  ) => location == null ? issue : issue.at(location);

  static String _childLocation(String? parent, String child) =>
      parent == null ? child : '$parent, $child';
}
