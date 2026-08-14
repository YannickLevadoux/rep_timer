import '../models/training.dart';
import '../models/group_type.dart';
import '../validation/business_validation.dart';
import 'json_prefs_storage.dart';

/// Contrat minimal de persistance des séances utilisé par l'accueil et les
/// cas d'usage qui doivent rester testables sans SharedPreferences.
abstract interface class TrainingStore {
  Future<StorageReadResult<List<Training>>> loadTrainings();

  Future<void> addOrUpdateTraining(Training training);

  Future<void> deleteTraining(String id);
}

/// Sauvegarde locale des séances (persistées en JSON via SharedPreferences).
/// Fonctionne directement sur Android/iOS/desktop, sans configuration native.
class TrainingStorage implements TrainingStore {
  static const storageKey = 'trainings';

  final JsonListStorage<Training> _storage = JsonListStorage<Training>(
    storageKey: storageKey,
    fromJson: _trainingFromJson,
    toJson: (t) => t.toJson(),
  );

  @override
  Future<StorageReadResult<List<Training>>> loadTrainings() =>
      _storage.loadList();

  Future<void> saveTrainings(List<Training> trainings) =>
      _storage.saveList(trainings);

  @override
  Future<void> addOrUpdateTraining(Training training) async {
    final normalized = BusinessValidation.normalizedTrainingCopy(training);
    BusinessValidation.requireValidTraining(normalized);
    final trainings = await _healthyTrainingsForMutation();
    final index = trainings.indexWhere((t) => t.id == normalized.id);

    if (index >= 0) {
      trainings[index] = normalized;
    } else {
      trainings.add(normalized);
    }

    await saveTrainings(trainings);
  }

  @override
  Future<void> deleteTraining(String id) async {
    final trainings = await _healthyTrainingsForMutation();
    trainings.removeWhere((t) => t.id == id);
    await saveTrainings(trainings);
  }

  Future<List<Training>> _healthyTrainingsForMutation() async {
    final result = await loadTrainings();
    return switch (result) {
      StorageNoData<List<Training>>() => <Training>[],
      StorageReadSuccess<List<Training>>(:final data) => List.of(data),
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

  static Training _trainingFromJson(Map<String, dynamic> json) {
    final training = Training.fromJson(json);
    for (final group in training.groups) {
      if (group.type == GroupType.free ||
          group.type == GroupType.variableRepetitions) {
        continue;
      }
      final issues = BusinessValidation.validateGroup(group);
      if (issues.isNotEmpty) throw BusinessValidationException(issues);
    }
    return training;
  }
}
