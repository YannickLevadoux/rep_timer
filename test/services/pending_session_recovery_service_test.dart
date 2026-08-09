import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/session_checkpoint.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/json_prefs_storage.dart';
import 'package:rep_timer/services/pending_session_recovery_service.dart';
import 'package:rep_timer/services/session_checkpoint_storage.dart';
import 'package:rep_timer/services/training_storage.dart';

void main() {
  final now = DateTime(2026, 8, 9, 12);

  test('ne fait rien lorsqu’aucun checkpoint n’existe', () async {
    final checkpoints = _FakeCheckpointStore(const StorageNoData());
    final service = _service(
      checkpoints: checkpoints,
      trainings: _FakeTrainingStore(const StorageNoData()),
      now: now,
    );

    final decision = await service.resolve();

    expect(
      decision,
      isA<NoPendingSession>().having(
        (value) => value.reason,
        'reason',
        NoPendingSessionReason.absent,
      ),
    );
    expect(checkpoints.clearCalls, 0);
  });

  test('reprend un checkpoint valide associé à sa séance', () async {
    final checkpoint = _checkpoint(savedAt: now);
    final training = _training('training');
    final service = _service(
      checkpoints: _FakeCheckpointStore(StorageReadSuccess(checkpoint)),
      trainings: _FakeTrainingStore(StorageReadSuccess([training])),
      now: now,
    );

    final decision = await service.resolve();

    expect(decision, isA<ResumePendingSession>());
    final resume = decision as ResumePendingSession;
    expect(resume.training, same(training));
    expect(resume.checkpoint, same(checkpoint));
    expect(resume.trainingStorageWarning, isFalse);
  });

  test('expire et supprime un checkpoint de plus de 24 heures', () async {
    final checkpoints = _FakeCheckpointStore(
      StorageReadSuccess(
        _checkpoint(
          savedAt: now.subtract(const Duration(hours: 24, seconds: 1)),
        ),
      ),
    );
    final service = _service(
      checkpoints: checkpoints,
      trainings: _FakeTrainingStore(const StorageNoData()),
      now: now,
    );

    final decision = await service.resolve();

    expect(
      decision,
      isA<NoPendingSession>().having(
        (value) => value.reason,
        'reason',
        NoPendingSessionReason.expired,
      ),
    );
    expect(checkpoints.clearCalls, 1);
  });

  test(
    'supprime le checkpoint si la séance est certainement absente',
    () async {
      final checkpoints = _FakeCheckpointStore(
        StorageReadSuccess(_checkpoint(savedAt: now)),
      );
      final service = _service(
        checkpoints: checkpoints,
        trainings: _FakeTrainingStore(const StorageReadSuccess([])),
        now: now,
      );

      final decision = await service.resolve();

      expect(
        decision,
        isA<NoPendingSession>().having(
          (value) => value.reason,
          'reason',
          NoPendingSessionReason.trainingMissing,
        ),
      );
      expect(checkpoints.clearCalls, 1);
    },
  );

  test('conserve le checkpoint si les séances sont partielles', () async {
    final checkpoints = _FakeCheckpointStore(
      StorageReadSuccess(_checkpoint(savedAt: now)),
    );
    final service = _service(
      checkpoints: checkpoints,
      trainings: _FakeTrainingStore(
        const StorageReadPartial([], rejectedIndexes: [0]),
      ),
      now: now,
    );

    final decision = await service.resolve();

    expect(
      decision,
      isA<PendingSessionRecoveryBlocked>()
          .having(
            (value) => value.reason,
            'reason',
            PendingSessionBlockedReason.trainingsPartial,
          )
          .having(
            (value) => value.trainingStorageWarning,
            'training warning',
            isTrue,
          ),
    );
    expect(decision.blocksSessionStart, isTrue);
    expect(checkpoints.clearCalls, 0);
  });

  test('conserve le checkpoint si les séances sont illisibles', () async {
    final checkpoints = _FakeCheckpointStore(
      StorageReadSuccess(_checkpoint(savedAt: now)),
    );
    final service = _service(
      checkpoints: checkpoints,
      trainings: _FakeTrainingStore(StorageReadFailure(_readError())),
      now: now,
    );

    final decision = await service.resolve();

    expect(
      decision,
      isA<PendingSessionRecoveryBlocked>().having(
        (value) => value.reason,
        'reason',
        PendingSessionBlockedReason.trainingsUnreadable,
      ),
    );
    expect(decision.blocksSessionStart, isTrue);
    expect(checkpoints.clearCalls, 0);
  });

  test(
    'conserve un checkpoint partiel ou illisible sans lire les séances',
    () async {
      for (final checkpointResult in <StorageReadResult<SessionCheckpoint>>[
        StorageReadPartial(
          _checkpoint(savedAt: now),
          rejectedIndexes: const [0],
        ),
        StorageReadFailure(_readError()),
      ]) {
        final checkpoints = _FakeCheckpointStore(checkpointResult);
        final trainings = _FakeTrainingStore(const StorageNoData());
        final decision = await _service(
          checkpoints: checkpoints,
          trainings: trainings,
          now: now,
        ).resolve();

        expect(decision, isA<PendingSessionRecoveryBlocked>());
        expect(decision.blocksSessionStart, isTrue);
        expect(checkpoints.clearCalls, 0);
        expect(trainings.loadCalls, 0);
      }
    },
  );

  test('reprend une séance retrouvée dans une lecture partielle', () async {
    final training = _training('training');
    final service = _service(
      checkpoints: _FakeCheckpointStore(
        StorageReadSuccess(_checkpoint(savedAt: now)),
      ),
      trainings: _FakeTrainingStore(
        StorageReadPartial([training], rejectedIndexes: const [1]),
      ),
      now: now,
    );

    final decision = await service.resolve();

    expect(decision, isA<ResumePendingSession>());
    expect(decision.trainingStorageWarning, isTrue);
  });

  test('bloque la reprise d’une séance métier invalide sans effacer', () async {
    final checkpoints = _FakeCheckpointStore(
      StorageReadSuccess(_checkpoint(savedAt: now)),
    );
    final invalidTraining = Training(
      id: 'training',
      name: '',
      groups: const [],
      createdAt: DateTime(2026),
    );
    final service = _service(
      checkpoints: checkpoints,
      trainings: _FakeTrainingStore(StorageReadSuccess([invalidTraining])),
      now: now,
    );

    final decision = await service.resolve();

    expect(
      decision,
      isA<PendingSessionRecoveryBlocked>()
          .having(
            (value) => value.reason,
            'reason',
            PendingSessionBlockedReason.invalidTraining,
          )
          .having(
            (value) => value.validationIssue,
            'validation issue',
            isNotNull,
          ),
    );
    expect(checkpoints.clearCalls, 0);
  });
}

PendingSessionRecoveryService _service({
  required _FakeCheckpointStore checkpoints,
  required _FakeTrainingStore trainings,
  required DateTime now,
}) => PendingSessionRecoveryService(
  checkpointStorage: checkpoints,
  trainingStorage: trainings,
  now: () => now,
);

class _FakeTrainingStore implements TrainingStore {
  _FakeTrainingStore(this.result);

  final StorageReadResult<List<Training>> result;
  int loadCalls = 0;

  @override
  Future<StorageReadResult<List<Training>>> loadTrainings() async {
    loadCalls++;
    return result;
  }

  @override
  Future<void> addOrUpdateTraining(Training training) async {}

  @override
  Future<void> deleteTraining(String id) async {}
}

class _FakeCheckpointStore implements SessionCheckpointStore {
  _FakeCheckpointStore(this.result);

  final StorageReadResult<SessionCheckpoint> result;
  int clearCalls = 0;

  @override
  Future<StorageReadResult<SessionCheckpoint>> loadCheckpoint() async => result;

  @override
  Future<void> clearCheckpoint() async {
    clearCalls++;
  }

  @override
  Future<void> saveCheckpoint(SessionCheckpoint checkpoint) async {}
}

SessionCheckpoint _checkpoint({required DateTime savedAt}) => SessionCheckpoint(
  trainingId: 'training',
  currentIndex: 0,
  completed: const [false],
  globalElapsed: Duration.zero,
  stepElapsed: Duration.zero,
  paused: false,
  savedAt: savedAt,
  stepActualDurations: const [],
);

Training _training(String id) => Training(
  id: id,
  name: 'Séance',
  groups: [
    ExerciseGroup(
      id: 'group',
      name: 'Groupe',
      items: [
        TrainingItem(
          type: ItemType.exercise,
          name: 'Exercice',
          duration: const Duration(seconds: 30),
        ),
      ],
    ),
  ],
  createdAt: DateTime(2026),
);

StorageReadException _readError() => StorageReadException(
  kind: StorageReadErrorKind.invalidJson,
  cause: const FormatException('secret payload'),
  stackTrace: StackTrace.empty,
);
