import 'package:flutter/foundation.dart';

import '../models/training.dart';
import '../services/json_prefs_storage.dart';
import '../services/training_storage.dart';
import '../utils/id_generator.dart';
import '../utils/validation_messages.dart';
import '../validation/business_validation.dart';

/// État et mutations de la liste affichée sur l'accueil.
class HomeController extends ChangeNotifier {
  HomeController({TrainingStorage? storage, IdGenerator? idGenerator})
    : _storage = storage ?? TrainingStorage(),
      _idGenerator = idGenerator ?? IdGenerator();

  final TrainingStorage _storage;
  final IdGenerator _idGenerator;

  List<Training> trainings = const [];
  bool loading = true;
  bool storageWarning = false;
  bool storageFailure = false;
  bool checkpointWarning = false;
  String? expandedTrainingId;
  bool _disposed = false;

  Future<void> loadTrainings() async {
    final result = await _storage.loadTrainings();
    if (_disposed) return;

    switch (result) {
      case StorageNoData<List<Training>>():
        trainings = const [];
        storageWarning = false;
        storageFailure = false;
      case StorageReadSuccess<List<Training>>(:final data):
        trainings = data;
        storageWarning = false;
        storageFailure = false;
      case StorageReadPartial<List<Training>>(:final data):
        trainings = data;
        storageWarning = true;
        storageFailure = false;
      case StorageReadFailure<List<Training>>():
        trainings = const [];
        storageWarning = false;
        storageFailure = true;
    }
    loading = false;
    notifyListeners();
  }

  void toggleExpanded(String trainingId) {
    if (_disposed) return;
    expandedTrainingId = expandedTrainingId == trainingId ? null : trainingId;
    notifyListeners();
  }

  void reportStorageWarning() {
    if (_disposed || storageWarning) return;
    storageWarning = true;
    notifyListeners();
  }

  void reportCheckpointWarning() {
    if (_disposed || checkpointWarning) return;
    checkpointWarning = true;
    notifyListeners();
  }

  /// Duplique puis recharge la liste. Retourne un message utilisateur en cas
  /// d'échec métier ou lorsque le stockage doit être protégé.
  Future<String?> duplicateTraining(Training training, String name) async {
    final duplicate = training.duplicate(name: name, newId: _idGenerator.next);
    try {
      await _storage.addOrUpdateTraining(duplicate);
    } on BusinessValidationException catch (error) {
      return 'Duplication impossible : ${validationMessage(error.issues.first)}';
    } on StorageMutationBlockedException {
      reportStorageWarning();
      return "Duplication impossible : certaines séances n'ont pas pu être lues.";
    }

    await loadTrainings();
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
