import 'validation_contract.dart';

/// Validation des quantités et durées programmées.
abstract final class NumericValidation {
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
}
