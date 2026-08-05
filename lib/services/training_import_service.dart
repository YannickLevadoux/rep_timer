import '../models/backup_import_models.dart';
import '../models/training.dart';
import '../utils/id_generator.dart';
import '../validation/business_validation.dart';
import 'backup_import_exception.dart';
import 'json_prefs_storage.dart';
import 'training_storage.dart';

/// Adaptateur minimal du format historique v1, sans aucun chemin d'encodage.
class TrainingImportService {
  TrainingImportService({TrainingStorage? storage, IdGenerator? idGenerator})
    : _storage = storage ?? TrainingStorage(),
      _idGenerator = idGenerator ?? IdGenerator();

  final TrainingStorage _storage;
  final IdGenerator _idGenerator;

  V1ImportPlan prepareV1(Map<String, dynamic> decoded) {
    final rawTrainings = decoded['trainings'];
    if (rawTrainings is! List<dynamic>) {
      throw const BackupImportException(
        BackupImportFailureKind.incompleteSchema,
      );
    }

    final imported = <Training>[];
    for (var index = 0; index < rawTrainings.length; index++) {
      final Training parsed;
      try {
        final raw = rawTrainings[index];
        if (raw is! Map<String, dynamic>) throw const FormatException();
        parsed = Training.fromJson(raw);
      } on Object {
        throw BackupImportException(
          BackupImportFailureKind.invalidTraining,
          entityIndex: index,
        );
      }

      final candidate = BusinessValidation.normalizedTrainingCopy(
        Training(
          id: parsed.id,
          name: parsed.name,
          createdAt: parsed.createdAt,
          groups: parsed.groups,
        ),
      );
      final issues = BusinessValidation.validateTraining(candidate);
      if (issues.isNotEmpty) {
        throw BackupImportException(
          BackupImportFailureKind.invalidTraining,
          entityIndex: index,
          issue: issues.first,
        );
      }
      imported.add(candidate);
    }
    return V1ImportPlan(List.unmodifiable(imported));
  }

  Future<int> applyV1(V1ImportPlan plan) async {
    final existing = _healthyTrainings(await _storage.loadTrainings());
    final imported = _withUniqueIds(plan.trainings, existing);
    await _storage.saveTrainings([...existing, ...imported]);
    return plan.trainings.length;
  }

  List<Training> _withUniqueIds(
    List<Training> imported,
    List<Training> existing,
  ) {
    final usedIds = {
      for (final training in existing) training.id,
      for (final training in existing)
        for (final group in training.groups) group.id,
    };
    String nextId() {
      while (true) {
        final candidate = _idGenerator.next();
        if (usedIds.add(candidate)) return candidate;
      }
    }

    return imported
        .map(
          (training) => Training(
            id: nextId(),
            name: training.name,
            createdAt: training.createdAt,
            groups: training.groups
                .map((group) => group.copyWith(id: nextId()))
                .toList(),
          ),
        )
        .toList();
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
}
