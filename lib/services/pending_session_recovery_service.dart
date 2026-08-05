import '../models/session_checkpoint.dart';
import '../models/training.dart';
import '../validation/business_validation.dart';
import 'json_prefs_storage.dart';
import 'session_checkpoint_storage.dart';
import 'training_storage.dart';

typedef PendingSessionRecovery = ({
  Training? training,
  SessionCheckpoint? checkpoint,
  BusinessValidationIssue? validationIssue,
  bool storageWarning,
  bool checkpointWarning,
});

/// Résout la séance éventuellement interrompue sans dépendre de l'interface.
class PendingSessionRecoveryService {
  PendingSessionRecoveryService({
    TrainingStorage? trainingStorage,
    SessionCheckpointStorage? checkpointStorage,
    DateTime Function()? now,
  }) : _trainingStorage = trainingStorage ?? TrainingStorage(),
       _checkpointStorage = checkpointStorage ?? SessionCheckpointStorage(),
       _now = now ?? DateTime.now;

  final TrainingStorage _trainingStorage;
  final SessionCheckpointStorage _checkpointStorage;
  final DateTime Function() _now;

  Future<PendingSessionRecovery> resolve() async {
    final checkpointResult = await _checkpointStorage.loadCheckpoint();
    final SessionCheckpoint checkpoint;
    switch (checkpointResult) {
      case StorageNoData<SessionCheckpoint>():
        return _none();
      case StorageReadSuccess<SessionCheckpoint>(:final data):
        checkpoint = data;
      case StorageReadPartial<SessionCheckpoint>():
      case StorageReadFailure<SessionCheckpoint>():
        return _none(checkpointWarning: true);
    }

    if (_now().difference(checkpoint.savedAt) > const Duration(hours: 24)) {
      await _checkpointStorage.clearCheckpoint();
      return _none();
    }

    final trainingsResult = await _trainingStorage.loadTrainings();
    final List<Training> trainings;
    final bool storageWarning;
    final canConcludeTrainingIsMissing = switch (trainingsResult) {
      StorageNoData<List<Training>>() => true,
      StorageReadSuccess<List<Training>>() => true,
      StorageReadPartial<List<Training>>() => false,
      StorageReadFailure<List<Training>>() => false,
    };
    switch (trainingsResult) {
      case StorageNoData<List<Training>>():
        trainings = const [];
        storageWarning = false;
      case StorageReadSuccess<List<Training>>(:final data):
        trainings = data;
        storageWarning = false;
      case StorageReadPartial<List<Training>>(:final data):
        trainings = data;
        storageWarning = true;
      case StorageReadFailure<List<Training>>():
        return _none();
    }

    Training? training;
    for (final candidate in trainings) {
      if (candidate.id == checkpoint.trainingId) {
        training = candidate;
        break;
      }
    }

    if (training == null) {
      if (canConcludeTrainingIsMissing) {
        await _checkpointStorage.clearCheckpoint();
      }
      return _none(storageWarning: storageWarning);
    }

    final issues = BusinessValidation.validateTraining(training);
    if (issues.isNotEmpty) {
      return (
        training: null,
        checkpoint: null,
        validationIssue: issues.first,
        storageWarning: storageWarning,
        checkpointWarning: true,
      );
    }

    return (
      training: training,
      checkpoint: checkpoint,
      validationIssue: null,
      storageWarning: storageWarning,
      checkpointWarning: false,
    );
  }

  PendingSessionRecovery _none({
    bool storageWarning = false,
    bool checkpointWarning = false,
  }) => (
    training: null,
    checkpoint: null,
    validationIssue: null,
    storageWarning: storageWarning,
    checkpointWarning: checkpointWarning,
  );
}
