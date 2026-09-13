import '../models/exercise_group.dart';
import '../models/group_type.dart';
import '../models/training_item.dart';
import 'numeric_validation.dart';
import 'tabata_validation.dart';
import 'validation_contract.dart';

/// Contrats structurels propres aux groupes temporisés de la version 1.4.0.
abstract final class TimedGroupValidation {
  static List<BusinessValidationIssue> validate(
    ExerciseGroup group, {
    String? location,
  }) => switch (group.type) {
    GroupType.tabata => TabataValidation.validate(group, location: location),
    GroupType.amrap => _validateAmrap(group, location),
    GroupType.emom => _validateEmom(group, location),
    _ => const [],
  };

  static List<BusinessValidationIssue> _validateAmrap(
    ExerciseGroup group,
    String? location,
  ) {
    final issues = <BusinessValidationIssue>[];
    final item = group.items.firstOrNull;
    if (group.rounds != 1 ||
        group.items.length != 1 ||
        !_isTimedExercise(item) ||
        group.tabataConfig != null ||
        group.finalRestDuration != null) {
      issues.add(_structure(location));
    }
    final seconds = item?.duration?.inSeconds;
    if (seconds != null &&
        (seconds < BusinessLimits.minimumAmrapDuration.inSeconds ||
            seconds > BusinessLimits.maximumAmrapDuration.inSeconds)) {
      issues.add(
        BusinessValidationIssue(
          field: BusinessField.amrapDuration,
          code: seconds < BusinessLimits.minimumAmrapDuration.inSeconds
              ? BusinessValidationCode.belowMinimum
              : BusinessValidationCode.aboveMaximum,
          minimum: BusinessLimits.minimumAmrapDuration.inSeconds,
          maximum: BusinessLimits.maximumAmrapDuration.inSeconds,
          actual: seconds,
          location: location,
        ),
      );
    }
    _addOptionalDuration(
      issues,
      group.postGroupRestDuration,
      BusinessField.postGroupRestDuration,
      location,
    );
    return issues;
  }

  static List<BusinessValidationIssue> _validateEmom(
    ExerciseGroup group,
    String? location,
  ) {
    final issues = <BusinessValidationIssue>[];
    if (group.rounds < 1 || group.rounds > BusinessLimits.maximumEmomMinutes) {
      issues.add(
        BusinessValidationIssue(
          field: BusinessField.emomMinutes,
          code: group.rounds < 1
              ? BusinessValidationCode.belowMinimum
              : BusinessValidationCode.aboveMaximum,
          minimum: 1,
          maximum: BusinessLimits.maximumEmomMinutes,
          actual: group.rounds,
          location: location,
        ),
      );
    }
    final item = group.items.firstOrNull;
    if (group.items.length != 1 ||
        !_isTimedExercise(item) ||
        item?.duration != ExerciseGroup.defaultEmomInterval ||
        group.tabataConfig != null ||
        group.finalRestDuration != null) {
      issues.add(_structure(location));
    }
    _addOptionalDuration(
      issues,
      group.postGroupRestDuration,
      BusinessField.postGroupRestDuration,
      location,
    );
    return issues;
  }

  static bool _isTimedExercise(TrainingItem? item) =>
      item?.type == ItemType.exercise &&
      item?.duration != null &&
      item?.repetitions == null &&
      item?.isFreeDuration == false;

  static void _addOptionalDuration(
    List<BusinessValidationIssue> issues,
    Duration? value,
    BusinessField field,
    String? location,
  ) {
    if (value == null) return;
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

  static BusinessValidationIssue _structure(String? location) =>
      BusinessValidationIssue(
        field: BusinessField.groupStructure,
        code: BusinessValidationCode.invalidGroupStructure,
        location: location,
      );
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
