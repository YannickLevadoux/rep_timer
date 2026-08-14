import '../validation/business_validation.dart';
import 'backup_import_exception.dart';

/// Validation brute des groupes v2/v3 avant le décodage tolérant du modèle.
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
          (version == 3 && !v3FieldsPresent) ||
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
