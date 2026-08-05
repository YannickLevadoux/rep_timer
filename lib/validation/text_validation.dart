import 'package:characters/characters.dart';

import 'validation_contract.dart';

/// Normalisation et validation des textes visibles par l'utilisateur.
abstract final class TextValidation {
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
}
