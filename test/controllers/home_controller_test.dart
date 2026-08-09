import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/controllers/home_controller.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/services/json_prefs_storage.dart';
import 'package:rep_timer/services/pending_session_recovery_service.dart';
import 'package:rep_timer/services/training_storage.dart';

void main() {
  test(
    'expose explicitement chargement, vide, valide, partiel et échec',
    () async {
      final storage = _FakeTrainingStore(const StorageNoData());
      final controller = HomeController(storage: storage);
      addTearDown(controller.dispose);

      expect(controller.status, HomeLoadStatus.loading);

      await controller.loadTrainings();
      expect(controller.status, HomeLoadStatus.empty);
      expect(controller.trainings, isEmpty);

      storage.result = StorageReadSuccess([_training('one')]);
      await controller.loadTrainings();
      expect(controller.status, HomeLoadStatus.valid);
      expect(controller.trainings.single.id, 'one');

      storage.result = StorageReadPartial(
        [_training('recovered')],
        rejectedIndexes: const [1],
      );
      await controller.loadTrainings();
      expect(controller.status, HomeLoadStatus.partial);
      expect(controller.trainings.single.id, 'recovered');

      storage.result = StorageReadFailure(_readError());
      await controller.loadTrainings();
      expect(controller.status, HomeLoadStatus.failure);
      expect(controller.trainings, isEmpty);
    },
  );

  test('centralise les blocages des mutations et du démarrage', () async {
    final storage = _FakeTrainingStore(StorageReadSuccess([_training('one')]));
    final controller = HomeController(storage: storage);
    addTearDown(controller.dispose);

    await controller.loadTrainings();
    expect(controller.actions.trainingMutationsAllowed, isTrue);
    expect(controller.actions.sessionStartAllowed, isTrue);

    controller.applyRecoveryDecision(
      const PendingSessionRecoveryBlocked(
        reason: PendingSessionBlockedReason.checkpointUnreadable,
      ),
    );
    expect(controller.actions.trainingMutationsAllowed, isTrue);
    expect(controller.actions.sessionStartAllowed, isFalse);

    controller.applyRecoveryDecision(
      const PendingSessionRecoveryBlocked(
        reason: PendingSessionBlockedReason.trainingsPartial,
        warnAboutTrainingStorage: true,
      ),
    );
    expect(controller.status, HomeLoadStatus.partial);
    expect(controller.actions.trainingMutationsAllowed, isFalse);
    expect(controller.actions.sessionStartAllowed, isFalse);
  });
}

class _FakeTrainingStore implements TrainingStore {
  _FakeTrainingStore(this.result);

  StorageReadResult<List<Training>> result;

  @override
  Future<StorageReadResult<List<Training>>> loadTrainings() async => result;

  @override
  Future<void> addOrUpdateTraining(Training training) async {}

  @override
  Future<void> deleteTraining(String id) async {}
}

Training _training(String id) => Training(
  id: id,
  name: 'Séance $id',
  groups: const [],
  createdAt: DateTime(2026),
);

StorageReadException _readError() => StorageReadException(
  kind: StorageReadErrorKind.invalidJson,
  cause: const FormatException('secret payload'),
  stackTrace: StackTrace.empty,
);
