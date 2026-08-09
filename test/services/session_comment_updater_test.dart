import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/models/session_step.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/session_comment_updater.dart';
import 'package:rep_timer/services/training_changes_persistence.dart';
import 'package:rep_timer/services/training_storage.dart';

void main() {
  test(
    'propage et persiste le commentaire de toutes les occurrences',
    () async {
      final storage = _FakeTrainingStorage();
      final training = _variableTraining();
      final steps = buildSessionSteps(training);
      var changes = 0;

      await SessionCommentUpdater(trainingStorage: storage).update(
        comment: '  Technique propre  ',
        currentStep: steps.first,
        steps: steps,
        training: training,
        persistence: TrainingChangesPersistence.persistent,
        onChanged: () => changes++,
      );

      expect(training.groups.single.items.single.comment, 'Technique propre');
      expect(
        steps.map((step) => step.item.comment),
        everyElement('Technique propre'),
      );
      expect(storage.saved, [training]);
      expect(changes, 1);
    },
  );

  test('restaure tous les commentaires si la persistance échoue', () async {
    final storage = _FakeTrainingStorage(failure: StateError('échec'));
    final training = _variableTraining(comment: 'Avant');
    final steps = buildSessionSteps(training);
    var changes = 0;

    await expectLater(
      SessionCommentUpdater(trainingStorage: storage).update(
        comment: 'Après',
        currentStep: steps.first,
        steps: steps,
        training: training,
        persistence: TrainingChangesPersistence.persistent,
        onChanged: () => changes++,
      ),
      throwsStateError,
    );

    expect(training.groups.single.items.single.comment, 'Avant');
    expect(steps.map((step) => step.item.comment), everyElement('Avant'));
    expect(changes, 2);
  });

  test('garde la modification en mémoire sans appeler le stockage', () async {
    final storage = _FakeTrainingStorage();
    final training = _variableTraining();
    final steps = buildSessionSteps(training);

    await SessionCommentUpdater(trainingStorage: storage).update(
      comment: 'Mémoire',
      currentStep: steps.first,
      steps: steps,
      training: training,
      persistence: TrainingChangesPersistence.memoryOnly,
      onChanged: () {},
    );

    expect(steps.first.item.comment, 'Mémoire');
    expect(storage.saved, isEmpty);
  });
}

Training _variableTraining({String? comment}) => Training(
  id: 'training',
  name: 'Séance',
  groups: [
    ExerciseGroup(
      id: 'group',
      name: 'Pyramide',
      type: GroupType.variableRepetitions,
      repetitionSequence: [8, 10],
      items: [
        TrainingItem(
          type: ItemType.exercise,
          name: 'Squats',
          repetitions: 5,
          comment: comment,
        ),
      ],
    ),
  ],
  createdAt: DateTime(2026),
);

class _FakeTrainingStorage extends TrainingStorage {
  _FakeTrainingStorage({this.failure});

  final Object? failure;
  final List<Training> saved = [];

  @override
  Future<void> addOrUpdateTraining(Training training) async {
    if (failure case final failure?) throw failure;
    saved.add(training);
  }
}
