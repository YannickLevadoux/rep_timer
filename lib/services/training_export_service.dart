import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/training.dart';
import '../validation/business_validation.dart';
import 'json_prefs_storage.dart';
import 'training_storage.dart';

/// Identifiant de format, présent dans chaque fichier exporté. Permet de
/// faire évoluer la structure plus tard tout en sachant lire les anciens
/// exports (voir la validation de version dans [importFromJsonString]).
const int _exportFormatVersion = 1;
const String _appIdentifier = 'RepTimer';

/// Résultat d'un import, à afficher à l'utilisateur.
class ImportResult {
  final int importedCount;

  const ImportResult(this.importedCount);
}

/// Gère l'export de toutes les séances vers un fichier JSON partageable,
/// et l'import d'un tel fichier.
///
/// Format de fichier :
/// ```json
/// {
///   "app": "RepTimer",
///   "exportFormatVersion": 1,
///   "exportedAt": "<ISO8601>",
///   "trainings": [ <Training.toJson()>, ... ]
/// }
/// ```
/// Réutilise directement les toJson()/fromJson() déjà présents sur les
/// modèles : le format d'export est simplement une enveloppe versionnée
/// autour de la sérialisation déjà utilisée pour le stockage local.
class TrainingExportService {
  final TrainingStorage _storage;

  TrainingExportService({TrainingStorage? storage})
    : _storage = storage ?? TrainingStorage();

  /// Écrit un fichier d'export dans le répertoire temporaire de l'app et
  /// retourne son chemin, prêt à être partagé.
  Future<String> exportToFile() async {
    final trainings = _healthyTrainings(await _storage.loadTrainings());

    final payload = {
      'app': _appIdentifier,
      'exportFormatVersion': _exportFormatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'trainings': trainings.map((t) => t.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(payload);

    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/reptimer_export_$timestamp.json');
    await file.writeAsString(jsonString);

    return file.path;
  }

  /// Importe les séances contenues dans [content] (contenu brut d'un
  /// fichier d'export) et les ajoute à celles déjà présentes.
  ///
  /// Ne modifie et ne supprime jamais une séance existante : chaque
  /// séance importée (et chacun de ses groupes) reçoit un nouvel
  /// identifiant, garantissant l'absence de collision.
  Future<ImportResult> importFromJsonString(String content) async {
    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
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
    if (version > _exportFormatVersion) {
      throw FormatException(
        "Ce fichier a été exporté par une version plus récente de "
        "l'application (format v$version) et ne peut pas être importé ici. "
        "Mets à jour l'application.",
      );
    }

    final rawTrainings = decoded['trainings'] as List<dynamic>;

    final imported = <Training>[];

    // La totalité du fichier est d'abord désérialisée, normalisée et validée.
    // Aucune lecture destinée à une mutation, et surtout aucune écriture, ne
    // commence avant que toutes les séances aient passé le contrat métier.
    for (var index = 0; index < rawTrainings.length; index++) {
      final raw = rawTrainings[index];
      final Training parsed;
      try {
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
          // Copie profonde (voir ExerciseGroup.copyWith) : chaque groupe
          // importé reçoit un nouvel identifiant, et ses items sont
          // recopiés plutôt que partagés avec les objets décodés depuis
          // le fichier.
          groups: parsed.groups.map((g) => g.copyWith(id: _newId())).toList(),
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

  int _idCounter = 0;

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

  // Horodatage + compteur : évite toute collision même si plusieurs
  // identifiants sont générés dans la même microseconde (import de
  // plusieurs séances d'affilée).
  String _newId() => '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  String _importIssueMessage(int trainingIndex, BusinessValidationIssue issue) {
    final field = switch (issue.field) {
      BusinessField.trainingName => 'nom de séance',
      BusinessField.groupName => 'nom de groupe',
      BusinessField.exerciseName => "nom d'exercice",
      BusinessField.groupRounds => 'nombre de tours',
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
