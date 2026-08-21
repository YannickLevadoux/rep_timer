import 'package:flutter/foundation.dart';

import '../models/training.dart';
import '../services/json_prefs_storage.dart';
import '../services/pending_session_recovery_service.dart';
import '../services/training_storage.dart';
import '../utils/id_generator.dart';
import '../utils/validation_messages.dart';
import '../validation/business_validation.dart';
import 'home_state.dart';

export 'home_state.dart';

/// État et mutations de la liste affichée sur l'accueil.
class HomeController extends ChangeNotifier {
  HomeController({required this.storage, IdGenerator? idGenerator})
    : _idGenerator = idGenerator ?? IdGenerator();

  final TrainingStore storage;
  final IdGenerator _idGenerator;

  List<Training> trainings = const [];
  HomeLoadStatus status = HomeLoadStatus.loading;
  String? expandedTrainingId;
  bool _sessionStartBlocked = false;
  bool _partialRecoveryObservedWhileLoading = false;
  bool _disposed = false;

  HomeActionAvailability get actions => HomeActionAvailability(
    // Conserve les protections de stockage existantes : une lecture partielle
    // ou impossible interdit les écritures. Le chargement initial reste
    // protégé par le stockage lui-même au moment de la mutation.
    trainingMutationsAllowed:
        status != HomeLoadStatus.partial && status != HomeLoadStatus.failure,
    sessionStartAllowed: !_sessionStartBlocked,
  );

  bool get storageWarning => status == HomeLoadStatus.partial;
  bool get checkpointWarning => _sessionStartBlocked;

  Future<void> loadTrainings() async {
    final result = await storage.loadTrainings();
    if (_disposed) return;

    switch (result) {
      case StorageNoData<List<Training>>():
        trainings = const [];
        status = HomeLoadStatus.empty;
      case StorageReadSuccess<List<Training>>(:final data):
        trainings = data;
        status = data.isEmpty ? HomeLoadStatus.empty : HomeLoadStatus.valid;
      case StorageReadPartial<List<Training>>(:final data):
        trainings = data;
        status = HomeLoadStatus.partial;
      case StorageReadFailure<List<Training>>():
        trainings = const [];
        status = HomeLoadStatus.failure;
    }
    if (_partialRecoveryObservedWhileLoading &&
        (status == HomeLoadStatus.empty || status == HomeLoadStatus.valid)) {
      status = HomeLoadStatus.partial;
    }
    _partialRecoveryObservedWhileLoading = false;
    _notify();
  }

  /// Applique les seules conséquences de présentation d'une décision de
  /// reprise. Le widget n'a donc pas à déduire les actions autorisées.
  void applyRecoveryDecision(PendingSessionRecoveryDecision decision) {
    if (_disposed) return;

    _sessionStartBlocked = decision.blocksSessionStart;
    if (decision.trainingStorageWarning) {
      if (status == HomeLoadStatus.loading) {
        _partialRecoveryObservedWhileLoading = true;
      } else if (status != HomeLoadStatus.failure) {
        status = HomeLoadStatus.partial;
      }
    }
    _notify();
  }

  void toggleExpanded(String trainingId) {
    if (_disposed) return;
    expandedTrainingId = expandedTrainingId == trainingId ? null : trainingId;
    _notify();
  }

  /// Duplique puis recharge la liste. Retourne un message utilisateur en cas
  /// d'échec métier ou lorsque le stockage doit être protégé.
  Future<String?> duplicateTraining(Training training, String name) async {
    final duplicate = training.duplicate(name: name, newId: _idGenerator.next);
    try {
      await storage.addOrUpdateTraining(duplicate);
    } on BusinessValidationException catch (error) {
      return 'Duplication impossible : ${validationMessage(error.issues.first)}';
    } on StorageMutationBlockedException {
      if (!_disposed) {
        status = HomeLoadStatus.partial;
        _notify();
      }
      return "Duplication impossible : certaines séances n'ont pas pu être lues.";
    }

    await loadTrainings();
    return null;
  }

  /// Supprime une séance puis recharge la liste, sans contourner les
  /// protections appliquées aux mutations depuis l'accueil.
  Future<void> deleteTraining(Training training) async {
    if (!actions.trainingMutationsAllowed) {
      throw const StorageMutationBlockedException(StorageBlockedState.partial);
    }

    try {
      await storage.deleteTraining(training.id);
    } on StorageMutationBlockedException {
      if (!_disposed) {
        status = HomeLoadStatus.partial;
        _notify();
      }
      rethrow;
    }

    if (expandedTrainingId == training.id) expandedTrainingId = null;
    await loadTrainings();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
