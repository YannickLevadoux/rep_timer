import 'package:characters/characters.dart';

import '../models/exercise_group.dart';
import '../models/training.dart';
import '../models/training_item.dart';

/// Bornes métier uniques de RepTimer.
abstract final class BusinessLimits {
  static const int minimumCount = 1;
  static const int maximumCount = 999;
  static const Duration minimumDuration = Duration(seconds: 1);
  static const Duration maximumDuration = Duration(hours: 2, seconds: 59);
  static const int maximumSessionSteps = 10000;
  static const int maximumNameCharacters = 50;
  static const int maximumCommentCharacters = 200;
  static const int maximumCommentLines = 3;
}

enum BusinessField {
  trainingName,
  quickTabataName,
  copyName,
  groupName,
  exerciseName,
  groupRounds,
  repetitions,
  duration,
  comment,
  sessionSteps,
  exerciseMode,
}

enum BusinessValidationCode {
  required,
  notANumber,
  belowMinimum,
  aboveMaximum,
  multipleLines,
  tooLong,
  tooManyLines,
  tooManySteps,
  invalidExerciseMode,
}

class BusinessValidationIssue {
  const BusinessValidationIssue({
    required this.field,
    required this.code,
    this.location,
    this.minimum,
    this.maximum,
    this.actual,
  });

  final BusinessField field;
  final BusinessValidationCode code;
  final String? location;
  final int? minimum;
  final int? maximum;
  final int? actual;

  BusinessValidationIssue at(String value) => BusinessValidationIssue(
    field: field,
    code: code,
    location: value,
    minimum: minimum,
    maximum: maximum,
    actual: actual,
  );
}

class BusinessValidationException implements Exception {
  const BusinessValidationException(this.issues);

  final List<BusinessValidationIssue> issues;

  @override
  String toString() => 'BusinessValidationException($issues)';
}

/// Validation métier pure, indépendante de Flutter et du stockage.
abstract final class BusinessValidation {
  static int visibleLength(String value) => value.characters.length;

  static String normalizeLineEndings(String value) =>
      value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  static String normalizeName(String value) => value.trim();

  static String copyNameProposal(
    String originalName, {
    String suffix = ' - Copie',
  }) {
    final firstLine = normalizeLineEndings(
      originalName,
    ).split('\n').first.trim();
    final safeBase = firstLine.isEmpty ? 'Séance' : firstLine;
    final available =
        BusinessLimits.maximumNameCharacters - visibleLength(suffix);
    final base = safeBase.characters.take(available).toString().trimRight();
    return '$base$suffix';
  }

  static String? normalizeComment(String? value) {
    if (value == null) return null;
    final normalized = normalizeLineEndings(value).trim();
    return normalized.isEmpty ? null : normalized;
  }

  static BusinessValidationIssue? validateName(
    String value, {
    required BusinessField field,
  }) {
    final normalized = normalizeName(value);
    if (normalized.isEmpty) {
      return BusinessValidationIssue(
        field: field,
        code: BusinessValidationCode.required,
      );
    }
    if (normalizeLineEndings(normalized).contains('\n')) {
      return BusinessValidationIssue(
        field: field,
        code: BusinessValidationCode.multipleLines,
      );
    }
    final length = visibleLength(normalized);
    if (length > BusinessLimits.maximumNameCharacters) {
      return BusinessValidationIssue(
        field: field,
        code: BusinessValidationCode.tooLong,
        maximum: BusinessLimits.maximumNameCharacters,
        actual: length,
      );
    }
    return null;
  }

  static BusinessValidationIssue? validateComment(String? value) {
    final normalized = normalizeComment(value);
    if (normalized == null) return null;
    final length = visibleLength(normalized);
    if (length > BusinessLimits.maximumCommentCharacters) {
      return BusinessValidationIssue(
        field: BusinessField.comment,
        code: BusinessValidationCode.tooLong,
        maximum: BusinessLimits.maximumCommentCharacters,
        actual: length,
      );
    }
    final lines = '\n'.allMatches(normalized).length + 1;
    if (lines > BusinessLimits.maximumCommentLines) {
      return BusinessValidationIssue(
        field: BusinessField.comment,
        code: BusinessValidationCode.tooManyLines,
        maximum: BusinessLimits.maximumCommentLines,
        actual: lines,
      );
    }
    return null;
  }

  static BusinessValidationIssue? validateCount(
    int? value, {
    required BusinessField field,
  }) {
    if (value == null) {
      return BusinessValidationIssue(
        field: field,
        code: BusinessValidationCode.required,
      );
    }
    if (value < BusinessLimits.minimumCount) {
      return BusinessValidationIssue(
        field: field,
        code: BusinessValidationCode.belowMinimum,
        minimum: BusinessLimits.minimumCount,
        actual: value,
      );
    }
    if (value > BusinessLimits.maximumCount) {
      return BusinessValidationIssue(
        field: field,
        code: BusinessValidationCode.aboveMaximum,
        maximum: BusinessLimits.maximumCount,
        actual: value,
      );
    }
    return null;
  }

  static BusinessValidationIssue? validateCountText(
    String value, {
    required BusinessField field,
  }) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return BusinessValidationIssue(
        field: field,
        code: BusinessValidationCode.required,
      );
    }
    final parsed = int.tryParse(normalized);
    if (parsed == null) {
      return BusinessValidationIssue(
        field: field,
        code: BusinessValidationCode.notANumber,
      );
    }
    return validateCount(parsed, field: field);
  }

  static BusinessValidationIssue? validateDuration(Duration? value) {
    if (value == null) {
      return const BusinessValidationIssue(
        field: BusinessField.duration,
        code: BusinessValidationCode.required,
      );
    }
    if (value < BusinessLimits.minimumDuration) {
      return BusinessValidationIssue(
        field: BusinessField.duration,
        code: BusinessValidationCode.belowMinimum,
        minimum: BusinessLimits.minimumDuration.inSeconds,
        actual: value.inSeconds,
      );
    }
    if (value > BusinessLimits.maximumDuration) {
      return BusinessValidationIssue(
        field: BusinessField.duration,
        code: BusinessValidationCode.aboveMaximum,
        maximum: BusinessLimits.maximumDuration.inSeconds,
        actual: value.inSeconds,
      );
    }
    return null;
  }

  static List<BusinessValidationIssue> validateItem(
    TrainingItem item, {
    String? location,
  }) {
    final issues = <BusinessValidationIssue>[];
    if (item.type == ItemType.rest) {
      final durationIssue = validateDuration(item.duration);
      if (durationIssue != null) issues.add(_located(durationIssue, location));
      return issues;
    }

    final nameIssue = validateName(
      item.name,
      field: BusinessField.exerciseName,
    );
    if (nameIssue != null) issues.add(_located(nameIssue, location));

    final commentIssue = validateComment(item.comment);
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
      final repetitionsIssue = validateCount(
        item.repetitions,
        field: BusinessField.repetitions,
      );
      if (repetitionsIssue != null) {
        issues.add(_located(repetitionsIssue, location));
      }
    } else if (hasDuration) {
      final durationIssue = validateDuration(item.duration);
      if (durationIssue != null) issues.add(_located(durationIssue, location));
    }
    return issues;
  }

  static List<BusinessValidationIssue> validateGroup(
    ExerciseGroup group, {
    String? location,
  }) {
    final issues = <BusinessValidationIssue>[];
    final nameIssue = validateName(group.name, field: BusinessField.groupName);
    if (nameIssue != null) issues.add(_located(nameIssue, location));
    final roundsIssue = validateCount(
      group.rounds,
      field: BusinessField.groupRounds,
    );
    if (roundsIssue != null) issues.add(_located(roundsIssue, location));
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
    final nameIssue = validateName(
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
    name: normalizeName(training.name),
    createdAt: training.createdAt,
    groups: training.groups
        .map(
          (group) => ExerciseGroup(
            id: group.id,
            name: normalizeName(group.name),
            type: group.type,
            expanded: group.expanded,
            rounds: group.rounds,
            items: group.items
                .map(
                  (item) => TrainingItem(
                    type: item.type,
                    name: item.type == ItemType.rest
                        ? item.name
                        : normalizeName(item.name),
                    repetitions: item.repetitions,
                    duration: item.duration,
                    isFreeDuration: item.isFreeDuration,
                    comment: normalizeComment(item.comment),
                    iconName: item.iconName,
                  ),
                )
                .toList(),
          ),
        )
        .toList(),
  );

  /// Calcule la borne de sécurité sans développer la séance en mémoire.
  /// Retourne dès que la limite est dépassée, ce qui évite aussi les grands
  /// produits inutiles issus de données importées ou anciennes.
  static int sessionStepUpperBound(
    Training training, {
    int stopAfter = BusinessLimits.maximumSessionSteps,
  }) {
    var total = 0;
    for (final group in training.groups) {
      if (group.rounds <= 0 || group.items.isEmpty) continue;
      final remaining = stopAfter - total;
      if (group.rounds > remaining ~/ group.items.length) {
        return stopAfter + 1;
      }
      total += group.items.length * group.rounds;
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
