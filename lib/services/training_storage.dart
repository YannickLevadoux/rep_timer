import '../models/training.dart';
import 'json_prefs_storage.dart';

/// Sauvegarde locale des séances (persistées en JSON via SharedPreferences).
/// Fonctionne directement sur Android/iOS/desktop, sans configuration native.
class TrainingStorage {
  static const _storageKey = 'trainings';

  final JsonListStorage<Training> _storage = JsonListStorage<Training>(
    storageKey: _storageKey,
    fromJson: Training.fromJson,
    toJson: (t) => t.toJson(),
  );

  Future<StorageReadResult<List<Training>>> loadTrainings() =>
      _storage.loadList();

  Future<void> saveTrainings(List<Training> trainings) =>
      _storage.saveList(trainings);

  Future<void> addOrUpdateTraining(Training training) async {
    final trainings = await _healthyTrainingsForMutation();
    final index = trainings.indexWhere((t) => t.id == training.id);

    if (index >= 0) {
      trainings[index] = training;
    } else {
      trainings.add(training);
    }

    await saveTrainings(trainings);
  }

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
}
