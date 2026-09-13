import '../validation/business_validation.dart';
import 'backup_import_exception.dart';

/// Validation brute propre à chaque version avant le décodage du modèle.
abstract final class BackupGroupValidator {
  static void validate(
    Map<String, dynamic> training,
    int trainingIndex, {
    required int version,
  }) {
    final groups = training['groups'];
    if (groups is! List<dynamic>) {
      throw _invalidTraining(trainingIndex);
    }

    for (var groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      final rawGroup = groups[groupIndex];
      if (rawGroup is! Map<String, dynamic>) {
        throw _invalidTraining(trainingIndex);
      }
      final type = rawGroup['type'];
      final acceptedTypes = version == 2
          ? const {'free', 'variableRepetitions'}
          : const {'free', 'variableRepetitions', 'tabata', 'amrap', 'emom'};
      if (!acceptedTypes.contains(type)) {
        throw const BackupImportException(
          BackupImportFailureKind.incompatibleData,
        );
      }

      if (version == 4 && type == 'tabata') {
        _validateV4Tabata(rawGroup);
        _validateSequence(rawGroup, trainingIndex, groupIndex);
        continue;
      }
      if (version == 3 && rawGroup.containsKey('tabata')) {
        throw const BackupImportException(
          BackupImportFailureKind.incompatibleData,
        );
      }
      if (version == 4 && rawGroup.containsKey('tabata')) {
        throw const BackupImportException(
          BackupImportFailureKind.incompatibleData,
        );
      }

      final rounds = rawGroup['rounds'];
      final rawSequence = rawGroup['repetitionSequence'];
      final finalRest = rawGroup['finalRestDurationSeconds'];
      final postGroupRest = rawGroup['postGroupRestDurationSeconds'];
      final v3FieldsPresent =
          rawGroup.containsKey('type') &&
          rawGroup.containsKey('repetitionSequence') &&
          rawGroup.containsKey('finalRestDurationSeconds') &&
          rawGroup.containsKey('postGroupRestDurationSeconds');
      if (rounds is! int ||
          (rawSequence != null && rawSequence is! List<dynamic>) ||
          (type == 'variableRepetitions' && rawSequence == null) ||
          (version >= 3 && !v3FieldsPresent) ||
          (finalRest != null && finalRest is! int) ||
          (postGroupRest != null && postGroupRest is! int)) {
        throw const BackupImportException(
          BackupImportFailureKind.incompleteSchema,
        );
      }
      final sequence = rawSequence is List<dynamic>
          ? rawSequence
          : const <dynamic>[];
      _requireValidCount(
        rounds,
        BusinessField.groupRounds,
        trainingIndex,
        'groupe ${groupIndex + 1}',
      );
      _validateSequenceValues(sequence, trainingIndex, groupIndex);
    }
  }

  static void _validateV4Tabata(Map<String, dynamic> rawGroup) {
    final rawConfig = rawGroup['tabata'];
    final completeGroup =
        rawGroup.containsKey('repetitionSequence') &&
        rawGroup.containsKey('postGroupRestDurationSeconds') &&
        !rawGroup.containsKey('rounds') &&
        !rawGroup.containsKey('items') &&
        !rawGroup.containsKey('finalRestDurationSeconds');
    if (rawConfig is! Map<String, dynamic> || !completeGroup) {
      throw const BackupImportException(
        BackupImportFailureKind.incompleteSchema,
      );
    }
    final rounds = rawConfig['rounds'];
    final exercises = rawConfig['exercises'];
    final rest = rawConfig['restDurationSeconds'];
    final finalRest = rawConfig['finalRestDurationSeconds'];
    final completeConfig =
        rawConfig.containsKey('rounds') &&
        rawConfig.containsKey('exercises') &&
        rawConfig.containsKey('restDurationSeconds') &&
        rawConfig.containsKey('finalRestDurationSeconds');
    if (!completeConfig ||
        rounds is! int ||
        exercises is! List<dynamic> ||
        rest is! int ||
        (finalRest != null && finalRest is! int) ||
        exercises.any((exercise) => exercise is! Map<String, dynamic>)) {
      throw const BackupImportException(
        BackupImportFailureKind.incompleteSchema,
      );
    }
  }

  static void _validateSequence(
    Map<String, dynamic> rawGroup,
    int trainingIndex,
    int groupIndex,
  ) {
    final rawSequence = rawGroup['repetitionSequence'];
    final postRest = rawGroup['postGroupRestDurationSeconds'];
    if (rawSequence is! List<dynamic> ||
        (postRest != null && postRest is! int)) {
      throw const BackupImportException(
        BackupImportFailureKind.incompleteSchema,
      );
    }
    _validateSequenceValues(rawSequence, trainingIndex, groupIndex);
  }

  static void _validateSequenceValues(
    List<dynamic> sequence,
    int trainingIndex,
    int groupIndex,
  ) {
    for (var valueIndex = 0; valueIndex < sequence.length; valueIndex++) {
      final value = sequence[valueIndex];
      if (value is! int) {
        throw _invalidTraining(
          trainingIndex,
          const BusinessValidationIssue(
            field: BusinessField.groupRepetitionValue,
            code: BusinessValidationCode.notANumber,
          ).at(_location(groupIndex, valueIndex)),
        );
      }
      _requireValidCount(
        value,
        BusinessField.groupRepetitionValue,
        trainingIndex,
        _location(groupIndex, valueIndex),
      );
    }
  }

  static void _requireValidCount(
    int value,
    BusinessField field,
    int trainingIndex,
    String location,
  ) {
    final issue = BusinessValidation.validateCount(value, field: field);
    if (issue != null) {
      throw _invalidTraining(trainingIndex, issue.at(location));
    }
  }

  static BackupImportException _invalidTraining(
    int index, [
    BusinessValidationIssue? issue,
  ]) => BackupImportException(
    BackupImportFailureKind.invalidTraining,
    entityIndex: index,
    issue: issue,
  );

  static String _location(int groupIndex, int valueIndex) =>
      'groupe ${groupIndex + 1}, tour ${valueIndex + 1}';
}

@Deprecated('Utiliser BackupGroupValidator.')
abstract final class BackupV2GroupValidator {
  static void validate(
    Map<String, dynamic> training,
    int trainingIndex, {
    required int version,
  }) =>
      BackupGroupValidator.validate(training, trainingIndex, version: version);
}
