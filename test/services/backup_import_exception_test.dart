import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/services/backup_import_exception.dart';
import 'package:rep_timer/validation/business_validation.dart';

void main() {
  test('chaque échec d’import expose un message utilisateur sûr', () {
    for (final kind in BackupImportFailureKind.values) {
      final error = BackupImportException(kind);

      expect(error.userMessage, isNotEmpty);
      expect(error.toString(), 'BackupImportException($kind)');
    }
  });

  test('précise version, numéro et emplacement lorsque disponibles', () {
    expect(
      const BackupImportException(
        BackupImportFailureKind.unsupportedVersion,
        version: 4,
      ).userMessage,
      contains('(v4)'),
    );

    const issue = BusinessValidationIssue(
      field: BusinessField.exerciseName,
      code: BusinessValidationCode.required,
      location: 'groupe 2, exercice 3',
    );
    final error = const BackupImportException(
      BackupImportFailureKind.invalidTraining,
      entityIndex: 1,
      issue: issue,
    );

    expect(error.userMessage, contains('La séance 2'));
    expect(error.userMessage, contains('(groupe 2, exercice 3)'));
    expect(error.userMessage, contains('Ce champ est obligatoire.'));
  });
}
