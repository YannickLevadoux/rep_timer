import '../models/exercise_group.dart';
import '../models/training.dart';
import '../models/training_item.dart';
import 'numeric_validation.dart';
import 'text_validation.dart';
import 'training_validation.dart';
import 'validation_contract.dart';

export 'validation_contract.dart';

/// Façade stable des contrats métier de RepTimer.
///
/// Les règles sont réparties par responsabilité dans les validateurs
/// spécialisés. Cette façade conserve une API unique pour les écrans et les
/// services, sans leur faire connaître l'organisation interne.
abstract final class BusinessValidation {
  static int visibleLength(String value) => TextValidation.visibleLength(value);

  static String normalizeLineEndings(String value) =>
      TextValidation.normalizeLineEndings(value);

  static String normalizeName(String value) =>
      TextValidation.normalizeName(value);

  static String copyNameProposal(
    String originalName, {
    String suffix = ' - Copie',
  }) => TextValidation.copyNameProposal(originalName, suffix: suffix);

  static String? normalizeComment(String? value) =>
      TextValidation.normalizeComment(value);

  static BusinessValidationIssue? validateName(
    String value, {
    required BusinessField field,
  }) => TextValidation.validateName(value, field: field);

  static BusinessValidationIssue? validateComment(String? value) =>
      TextValidation.validateComment(value);

  static BusinessValidationIssue? validateCount(
    int? value, {
    required BusinessField field,
  }) => NumericValidation.validateCount(value, field: field);

  static BusinessValidationIssue? validateCountText(
    String value, {
    required BusinessField field,
  }) => NumericValidation.validateCountText(value, field: field);

  static BusinessValidationIssue? validateDuration(Duration? value) =>
      NumericValidation.validateDuration(value);

  static List<BusinessValidationIssue> validateItem(
    TrainingItem item, {
    String? location,
  }) => TrainingValidation.validateItem(item, location: location);

  static List<BusinessValidationIssue> validateGroup(
    ExerciseGroup group, {
    String? location,
  }) => TrainingValidation.validateGroup(group, location: location);

  static List<BusinessValidationIssue> validateTraining(Training training) =>
      TrainingValidation.validateTraining(training);

  static Training normalizedTrainingCopy(Training training) =>
      TrainingValidation.normalizedTrainingCopy(training);

  static int sessionStepUpperBound(
    Training training, {
    int stopAfter = BusinessLimits.maximumSessionSteps,
  }) =>
      TrainingValidation.sessionStepUpperBound(training, stopAfter: stopAfter);

  static BusinessValidationIssue? validateSessionStepLimit(Training training) =>
      TrainingValidation.validateSessionStepLimit(training);

  static void requireValidTraining(Training training) =>
      TrainingValidation.requireValidTraining(training);
}
