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

  test(
    'supprime la séance sélectionnée, recharge et nettoie la sélection',
    () async {
      final storage = _FakeTrainingStore(
        StorageReadSuccess([_training('one'), _training('two')]),
      );
      final controller = HomeController(storage: storage);
      addTearDown(controller.dispose);

      await controller.loadTrainings();
      controller.toggleExpanded('one');
      await controller.deleteTraining(controller.trainings.first);

      expect(storage.deletedIds, ['one']);
      expect(controller.trainings.map((training) => training.id), ['two']);
      expect(controller.expandedTrainingId, isNull);
    },
  );

  test('refuse la suppression lorsque les mutations sont bloquées', () async {
    final storage = _FakeTrainingStore(
      StorageReadPartial([_training('one')], rejectedIndexes: const [1]),
    );
    final controller = HomeController(storage: storage);
    addTearDown(controller.dispose);

    await controller.loadTrainings();
    controller.toggleExpanded('one');

    await expectLater(
      controller.deleteTraining(controller.trainings.single),
      throwsA(isA<StorageMutationBlockedException>()),
    );
    expect(storage.deletedIds, isEmpty);
    expect(controller.expandedTrainingId, 'one');
  });

  test('propage un blocage du stockage et protège la liste affichée', () async {
    final storage = _FakeTrainingStore(StorageReadSuccess([_training('one')]));
    final controller = HomeController(storage: storage);
    addTearDown(controller.dispose);

    await controller.loadTrainings();
    controller.toggleExpanded('one');
    storage.blockDeletion = true;

    await expectLater(
      controller.deleteTraining(controller.trainings.single),
      throwsA(isA<StorageMutationBlockedException>()),
    );
    expect(controller.status, HomeLoadStatus.partial);
    expect(controller.trainings.single.id, 'one');
    expect(controller.expandedTrainingId, 'one');
  });
}

class _FakeTrainingStore implements TrainingStore {
  _FakeTrainingStore(this.result);

  StorageReadResult<List<Training>> result;
  bool blockDeletion = false;
  final List<String> deletedIds = [];

  @override
  Future<StorageReadResult<List<Training>>> loadTrainings() async => result;

  @override
  Future<void> addOrUpdateTraining(Training training) async {}

  @override
  Future<void> deleteTraining(String id) async {
    if (blockDeletion) {
      throw const StorageMutationBlockedException(StorageBlockedState.partial);
    }
    deletedIds.add(id);
    if (result case StorageReadSuccess<List<Training>>(:final data)) {
      result = StorageReadSuccess(
        data.where((training) => training.id != id).toList(),
      );
    }
  }
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
