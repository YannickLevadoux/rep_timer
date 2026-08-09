import '../models/session_checkpoint.dart';
import '../models/training.dart';
import '../validation/business_validation.dart';
import 'json_prefs_storage.dart';
import 'session_checkpoint_storage.dart';
import 'training_storage.dart';

typedef PendingSessionClock = DateTime Function();

enum NoPendingSessionReason { absent, expired, trainingMissing }

enum PendingSessionBlockedReason {
  checkpointPartial,
  checkpointUnreadable,
  trainingsPartial,
  trainingsUnreadable,
  invalidTraining,
}

/// Décision métier de reprise. L'interface ne reçoit que cette décision : les
/// détails du stockage et les erreurs techniques restent confinés au service.
sealed class PendingSessionRecoveryDecision {
  const PendingSessionRecoveryDecision();

  bool get trainingStorageWarning => false;

  bool get blocksSessionStart => false;
}

final class NoPendingSession extends PendingSessionRecoveryDecision {
  const NoPendingSession(this.reason);

  final NoPendingSessionReason reason;
}

final class ResumePendingSession extends PendingSessionRecoveryDecision {
  const ResumePendingSession({
    required this.training,
    required this.checkpoint,
    this.trainingsPartiallyRead = false,
  });

  final Training training;
  final SessionCheckpoint checkpoint;
  final bool trainingsPartiallyRead;

  @override
  bool get trainingStorageWarning => trainingsPartiallyRead;
}

final class PendingSessionRecoveryBlocked
    extends PendingSessionRecoveryDecision {
  const PendingSessionRecoveryBlocked({
    required this.reason,
    this.validationIssue,
    this.warnAboutTrainingStorage = false,
  });

  final PendingSessionBlockedReason reason;
  final BusinessValidationIssue? validationIssue;
  final bool warnAboutTrainingStorage;

  @override
  bool get trainingStorageWarning => warnAboutTrainingStorage;

  @override
  bool get blocksSessionStart => true;
}

abstract interface class PendingSessionRecoveryResolver {
  Future<PendingSessionRecoveryDecision> resolve();
}

/// Résout la séance éventuellement interrompue sans dépendre de l'interface.
class PendingSessionRecoveryService implements PendingSessionRecoveryResolver {
  PendingSessionRecoveryService({
    required this.trainingStorage,
    required this.checkpointStorage,
    PendingSessionClock? now,
  }) : _now = now ?? DateTime.now;

  final TrainingStore trainingStorage;
  final SessionCheckpointStore checkpointStorage;
  final PendingSessionClock _now;

  @override
  Future<PendingSessionRecoveryDecision> resolve() async {
    final checkpointResult = await checkpointStorage.loadCheckpoint();
    final SessionCheckpoint checkpoint;
    switch (checkpointResult) {
      case StorageNoData<SessionCheckpoint>():
        return const NoPendingSession(NoPendingSessionReason.absent);
      case StorageReadSuccess<SessionCheckpoint>(:final data):
        checkpoint = data;
      case StorageReadPartial<SessionCheckpoint>():
        return const PendingSessionRecoveryBlocked(
          reason: PendingSessionBlockedReason.checkpointPartial,
        );
      case StorageReadFailure<SessionCheckpoint>():
        return const PendingSessionRecoveryBlocked(
          reason: PendingSessionBlockedReason.checkpointUnreadable,
        );
    }

    if (_now().difference(checkpoint.savedAt) > const Duration(hours: 24)) {
      await checkpointStorage.clearCheckpoint();
      return const NoPendingSession(NoPendingSessionReason.expired);
    }

    final trainingsResult = await trainingStorage.loadTrainings();
    final List<Training> trainings;
    final bool trainingsPartiallyRead;
    final bool canConcludeTrainingIsMissing;
    switch (trainingsResult) {
      case StorageNoData<List<Training>>():
        trainings = const [];
        trainingsPartiallyRead = false;
        canConcludeTrainingIsMissing = true;
      case StorageReadSuccess<List<Training>>(:final data):
        trainings = data;
        trainingsPartiallyRead = false;
        canConcludeTrainingIsMissing = true;
      case StorageReadPartial<List<Training>>(:final data):
        trainings = data;
        trainingsPartiallyRead = true;
        canConcludeTrainingIsMissing = false;
      case StorageReadFailure<List<Training>>():
        return const PendingSessionRecoveryBlocked(
          reason: PendingSessionBlockedReason.trainingsUnreadable,
        );
    }

    final training = trainings
        .where((candidate) => candidate.id == checkpoint.trainingId)
        .firstOrNull;

    if (training == null) {
      if (canConcludeTrainingIsMissing) {
        await checkpointStorage.clearCheckpoint();
        return const NoPendingSession(NoPendingSessionReason.trainingMissing);
      }
      return const PendingSessionRecoveryBlocked(
        reason: PendingSessionBlockedReason.trainingsPartial,
        warnAboutTrainingStorage: true,
      );
    }

    final issues = BusinessValidation.validateTraining(training);
    if (issues.isNotEmpty) {
      return PendingSessionRecoveryBlocked(
        reason: PendingSessionBlockedReason.invalidTraining,
        validationIssue: issues.first,
        warnAboutTrainingStorage: trainingsPartiallyRead,
      );
    }

    return ResumePendingSession(
      training: training,
      checkpoint: checkpoint,
      trainingsPartiallyRead: trainingsPartiallyRead,
    );
  }
}
