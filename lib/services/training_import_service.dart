import 'dart:convert';

import '../models/training.dart';
import '../validation/business_validation.dart';
import 'json_prefs_storage.dart';
import 'training_storage.dart';

const int _supportedImportVersion = 1;
const String _appIdentifier = 'RepTimer';

class ImportResult {
  const ImportResult(this.importedCount);

  final int importedCount;
}

/// Lecture historique des imports de séances v1.
///
/// La restauration complète des sauvegardes v2 sera ajoutée par l'issue 107.
/// Cette classe ne contient volontairement aucun chemin d'encodage ou d'export.
class TrainingImportService {
  TrainingImportService({TrainingStorage? storage})
    : _storage = storage ?? TrainingStorage();

  final TrainingStorage _storage;
  int _idCounter = 0;

  Future<ImportResult> importFromJsonString(String content) async {
    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(content) as Map<String, dynamic>;
    } on Object {
      throw const FormatException(
        "Le fichier sélectionné n'est pas un fichier JSON valide.",
      );
    }

    if (decoded['app'] != _appIdentifier || decoded['trainings'] is! List) {
      throw const FormatException(
        "Ce fichier ne semble pas être un export de RepTimer.",
      );
    }

    final version = decoded['exportFormatVersion'] as int? ?? 1;
    if (version > _supportedImportVersion) {
      throw FormatException(
        "Ce fichier a été exporté par une version plus récente de "
        "l'application (format v$version) et ne peut pas être importé ici. "
        "Mets à jour l'application.",
      );
    }

    final rawTrainings = decoded['trainings'] as List<dynamic>;
    final imported = <Training>[];
    for (var index = 0; index < rawTrainings.length; index++) {
      final Training parsed;
      try {
        final raw = rawTrainings[index];
        if (raw is! Map<String, dynamic>) throw const FormatException();
        parsed = Training.fromJson(raw);
      } on Object {
        throw FormatException(
          'Séance ${index + 1} : la structure des champs est invalide.',
        );
      }

      final candidate = BusinessValidation.normalizedTrainingCopy(
        Training(
          id: _newId(),
          name: parsed.name,
          createdAt: parsed.createdAt,
          groups: parsed.groups
              .map((group) => group.copyWith(id: _newId()))
              .toList(),
        ),
      );
      final issues = BusinessValidation.validateTraining(candidate);
      if (issues.isNotEmpty) {
        throw FormatException(_importIssueMessage(index, issues.first));
      }
      imported.add(candidate);
    }

    final existing = _healthyTrainings(await _storage.loadTrainings());
    await _storage.saveTrainings([...existing, ...imported]);
    return ImportResult(imported.length);
  }

  List<Training> _healthyTrainings(StorageReadResult<List<Training>> result) {
    return switch (result) {
      StorageNoData<List<Training>>() => <Training>[],
      StorageReadSuccess<List<Training>>(:final data) => data,
      StorageReadPartial<List<Training>>() =>
        throw const StorageMutationBlockedException(
          StorageBlockedState.partial,
        ),
      StorageReadFailure<List<Training>>(:final error) =>
        throw StorageMutationBlockedException(
          StorageBlockedState.unreadable,
          readError: error,
        ),
    };
  }

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  String _importIssueMessage(int trainingIndex, BusinessValidationIssue issue) {
    final field = switch (issue.field) {
      BusinessField.trainingName => 'nom de séance',
      BusinessField.groupName => 'nom de groupe',
      BusinessField.exerciseName => "nom d'exercice",
      BusinessField.groupRounds => 'nombre de tours',
      BusinessField.groupRepetitionSequence => 'suite de répétitions',
      BusinessField.groupRepetitionValue => 'valeur de répétitions',
      BusinessField.repetitions => 'nombre de répétitions',
      BusinessField.duration => 'durée',
      BusinessField.comment => 'commentaire',
      BusinessField.sessionSteps => "nombre d'étapes",
      BusinessField.exerciseMode => "mode d'exercice",
      BusinessField.quickTabataName || BusinessField.copyName => 'nom',
    };
    final reason = switch (issue.code) {
      BusinessValidationCode.required => 'valeur obligatoire',
      BusinessValidationCode.notANumber => 'nombre entier attendu',
      BusinessValidationCode.belowMinimum => 'minimum ${issue.minimum}',
      BusinessValidationCode.aboveMaximum => 'maximum ${issue.maximum}',
      BusinessValidationCode.multipleLines => 'une seule ligne autorisée',
      BusinessValidationCode.tooLong => 'maximum ${issue.maximum} caractères',
      BusinessValidationCode.tooManyLines => 'maximum ${issue.maximum} lignes',
      BusinessValidationCode.tooManySteps => 'maximum ${issue.maximum} étapes',
      BusinessValidationCode.invalidExerciseMode => 'mode incohérent',
    };
    final location = issue.location == null ? '' : ' (${issue.location})';
    return 'Séance ${trainingIndex + 1}, $field$location : $reason.';
  }
}
