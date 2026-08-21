import '../utils/validation_messages.dart';
import '../validation/business_validation.dart';

enum BackupImportFailureKind {
  invalidJson,
  wrongApplication,
  unsupportedVersion,
  incompleteSchema,
  incompatibleData,
  invalidTraining,
  invalidHistory,
  wrongTrainingImportPath,
  wrongRestorePath,
  emptyTrainingExport,
  restoreFailed,
  rollbackFailed,
}

/// Erreur d'import/restauration contrôlée, sans payload ni cause technique.
final class BackupImportException implements Exception {
  const BackupImportException(
    this.kind, {
    this.version,
    this.entityIndex,
    this.issue,
  });

  final BackupImportFailureKind kind;
  final int? version;
  final int? entityIndex;
  final BusinessValidationIssue? issue;

  String get userMessage => switch (kind) {
    BackupImportFailureKind.invalidJson =>
      "Le fichier sélectionné n'est pas un fichier JSON valide.",
    BackupImportFailureKind.wrongApplication =>
      "Ce fichier ne semble pas être une sauvegarde RepTimer.",
    BackupImportFailureKind.unsupportedVersion =>
      'Cette version de sauvegarde n’est pas prise en charge'
          '${version == null ? '.' : ' (v$version).'}',
    BackupImportFailureKind.incompleteSchema =>
      'La sauvegarde est incomplète et ne peut pas être utilisée.',
    BackupImportFailureKind.incompatibleData =>
      'La sauvegarde contient des données incompatibles.',
    BackupImportFailureKind.invalidTraining => _invalidTrainingMessage(),
    BackupImportFailureKind.invalidHistory =>
      "L'entrée d'historique ${(entityIndex ?? 0) + 1} est invalide.",
    BackupImportFailureKind.wrongTrainingImportPath =>
      'Ce fichier est une sauvegarde complète. Utilisez « Restaurer les '
          'données ».',
    BackupImportFailureKind.wrongRestorePath =>
      'Ce fichier contient des séances à ajouter. Utilisez « Importer des '
          'séances ».',
    BackupImportFailureKind.emptyTrainingExport =>
      "Ce fichier ne contient aucune séance à importer.",
    BackupImportFailureKind.restoreFailed =>
      "La restauration a échoué. Les données précédentes ont été rétablies.",
    BackupImportFailureKind.rollbackFailed =>
      'La restauration et la récupération des données précédentes ont échoué.',
  };

  String _invalidTrainingMessage() {
    final number = (entityIndex ?? 0) + 1;
    final location = issue?.location;
    final locationSuffix = location == null ? '' : ' ($location)';
    final detail = issue == null
        ? 'Sa structure est incompatible.'
        : validationMessage(issue!);
    return 'La séance $number est invalide$locationSuffix. $detail';
  }

  @override
  String toString() => 'BackupImportException($kind)';
}
