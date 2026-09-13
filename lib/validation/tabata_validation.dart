import '../models/exercise_group.dart';
import '../models/training_item.dart';
import 'numeric_validation.dart';
import 'validation_contract.dart';

abstract final class TabataValidation {
  static List<BusinessValidationIssue> validate(
    ExerciseGroup group, {
    String? location,
  }) {
    final issues = <BusinessValidationIssue>[];
    final config = group.tabataConfig;
    if (config == null) return [_structure(location)];
    _addCount(
      issues,
      config.rounds,
      BusinessLimits.maximumTabataRounds,
      BusinessField.tabataRounds,
      location,
    );
    _addCount(
      issues,
      config.exercises.length,
      BusinessLimits.maximumCount,
      BusinessField.tabataCycles,
      location,
    );
    final effortDuration = config.effortDuration;
    final coherentExercises =
        config.exercises.isNotEmpty &&
        config.exercises.every(
          (exercise) =>
              _isTimed(exercise, ItemType.exercise) &&
              exercise.duration == effortDuration,
        );
    final coherentProjection =
        group.rounds == config.exercises.length &&
        group.items.length == 2 &&
        _sameItem(group.items.first, config.exercises.firstOrNull) &&
        _isTimed(group.items.elementAtOrNull(1), ItemType.rest) &&
        group.items[1].duration == config.restDuration;
    if (!coherentExercises ||
        !coherentProjection ||
        group.postGroupRestDuration != null) {
      issues.add(_structure(location));
    }
    _addDuration(
      issues,
      config.restDuration,
      BusinessField.tabataRestDuration,
      location,
    );
    _addOptionalDuration(
      issues,
      config.finalRestDuration,
      BusinessField.finalRestDuration,
      location,
    );
    if (config.rounds > 1 && config.finalRestDuration == null) {
      issues.add(
        BusinessValidationIssue(
          field: BusinessField.finalRestDuration,
          code: BusinessValidationCode.required,
          location: location,
        ),
      );
    }
    return issues;
  }

  static bool _isTimed(TrainingItem? item, ItemType type) =>
      item?.type == type &&
      item?.duration != null &&
      item?.repetitions == null &&
      item?.isFreeDuration == false;

  static bool _sameItem(TrainingItem? first, TrainingItem? second) =>
      first != null &&
      second != null &&
      first.type == second.type &&
      first.name == second.name &&
      first.repetitions == second.repetitions &&
      first.duration == second.duration &&
      first.isFreeDuration == second.isFreeDuration &&
      first.comment == second.comment &&
      first.iconName == second.iconName;

  static void _addCount(
    List<BusinessValidationIssue> issues,
    int value,
    int maximum,
    BusinessField field,
    String? location,
  ) {
    if (value >= BusinessLimits.minimumCount && value <= maximum) return;
    issues.add(
      BusinessValidationIssue(
        field: field,
        code: value < BusinessLimits.minimumCount
            ? BusinessValidationCode.belowMinimum
            : BusinessValidationCode.aboveMaximum,
        minimum: BusinessLimits.minimumCount,
        maximum: maximum,
        actual: value,
        location: location,
      ),
    );
  }

  static void _addDuration(
    List<BusinessValidationIssue> issues,
    Duration value,
    BusinessField field,
    String? location,
  ) {
    final issue = NumericValidation.validateDuration(value);
    if (issue == null) return;
    issues.add(
      BusinessValidationIssue(
        field: field,
        code: issue.code,
        minimum: issue.minimum,
        maximum: issue.maximum,
        actual: issue.actual,
        location: location,
      ),
    );
  }

  static void _addOptionalDuration(
    List<BusinessValidationIssue> issues,
    Duration? value,
    BusinessField field,
    String? location,
  ) {
    if (value != null) _addDuration(issues, value, field, location);
  }

  static BusinessValidationIssue _structure(String? location) =>
      BusinessValidationIssue(
        field: BusinessField.groupStructure,
        code: BusinessValidationCode.invalidGroupStructure,
        location: location,
      );
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;

  T? elementAtOrNull(int index) => index < length ? this[index] : null;
}
