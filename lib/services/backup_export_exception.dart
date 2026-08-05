import '../utils/validation_messages.dart';
import '../validation/business_validation.dart';

enum BackupExportFailureKind {
  trainingsPartial,
  trainingsUnreadable,
  historyPartial,
  historyUnreadable,
  preferencesUnreadable,
  invalidTraining,
  fileWrite,
  share,
}

/// Erreur d'export contrôlée, sans contenu stocké ni cause technique exposée.
final class BackupExportException implements Exception {
  const BackupExportException(this.kind, {this.trainingIndex, this.issue});

  final BackupExportFailureKind kind;
  final int? trainingIndex;
  final BusinessValidationIssue? issue;

  String get userMessage => switch (kind) {
    BackupExportFailureKind.trainingsPartial =>
      "L'export est impossible : certaines séances n'ont pas pu être lues.",
    BackupExportFailureKind.trainingsUnreadable =>
      "L'export est impossible : les séances enregistrées sont illisibles.",
    BackupExportFailureKind.historyPartial =>
      "L'export est impossible : une partie de l'historique n'a pas pu être lue.",
    BackupExportFailureKind.historyUnreadable =>
      "L'export est impossible : l'historique enregistré est illisible.",
    BackupExportFailureKind.preferencesUnreadable =>
      "L'export est impossible : les préférences n'ont pas pu être lues.",
    BackupExportFailureKind.invalidTraining => _invalidTrainingMessage(),
    BackupExportFailureKind.fileWrite =>
      "La sauvegarde n'a pas pu être créée sur l'appareil.",
    BackupExportFailureKind.share =>
      "La sauvegarde a été créée, mais n'a pas pu être partagée.",
  };

  String _invalidTrainingMessage() {
    final number = (trainingIndex ?? 0) + 1;
    final location = issue?.location;
    final locationSuffix = location == null ? '' : ' ($location)';
    final detail = issue == null
        ? 'ses données ne respectent pas le format attendu.'
        : validationMessage(issue!);
    return "L'export est impossible : la séance $number est invalide"
        '$locationSuffix. $detail';
  }

  @override
  String toString() => 'BackupExportException($kind)';
}
