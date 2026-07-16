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

  Future<List<Training>> loadTrainings() => _storage.loadList();

  Future<void> saveTrainings(List<Training> trainings) =>
      _storage.saveList(trainings);

  Future<void> addOrUpdateTraining(Training training) async {
    final trainings = await loadTrainings();
    final index = trainings.indexWhere((t) => t.id == training.id);

    if (index >= 0) {
      trainings[index] = training;
    } else {
      trainings.add(training);
    }

    await saveTrainings(trainings);
  }

  Future<void> deleteTraining(String id) async {
    final trainings = await loadTrainings();
    trainings.removeWhere((t) => t.id == id);
    await saveTrainings(trainings);
  }
}
