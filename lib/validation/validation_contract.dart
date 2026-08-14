/// Bornes métier uniques de RepTimer.
abstract final class BusinessLimits {
  static const int minimumCount = 1;
  static const int maximumCount = 999;
  static const Duration minimumDuration = Duration(seconds: 1);
  static const Duration maximumDuration = Duration(hours: 2, seconds: 59);
  static const int maximumSessionSteps = 10000;
  static const int maximumEmomMinutes = 60;
  static const int maximumAmrapLaps = 999;
  static const Duration minimumAmrapDuration = Duration(minutes: 1);
  static const Duration maximumAmrapDuration = Duration(hours: 1);
  static const Duration maximumAmrapButtonDelay = Duration(seconds: 2);
  static const int maximumPreSessionCountdownSeconds = 15;
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
  groupRepetitionSequence,
  groupRepetitionValue,
  repetitions,
  duration,
  comment,
  sessionSteps,
  exerciseMode,
  groupStructure,
  finalRestDuration,
  postGroupRestDuration,
  amrapDuration,
  emomMinutes,
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
  invalidGroupStructure,
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
