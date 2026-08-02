import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/session_checkpoint.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/session_progress_state.dart';

void main() {
  test('la progression, les durées et les occurrences restent cohérentes', () {
    final state = SessionProgressState(training: _training());

    state.recordCurrentStepDuration(const Duration(seconds: 8));
    expect(state.completeCurrentStep(), SessionStepCompletion.advanced);
    expect(state.currentIndex, 1);
    expect(state.stepOccurrence, 1);
    expect(state.stepActualDurations.first, const Duration(seconds: 8));

    expect(state.jumpTo(0), isTrue);
    expect(state.currentIndex, 0);
    expect(state.stepOccurrence, 2);
    expect(state.completed, <bool>[true, false]);
  });

  test('un checkpoint valide restaure exactement la progression', () {
    final checkpoint = SessionCheckpoint(
      trainingId: 'training',
      currentIndex: 1,
      completed: <bool>[true, false],
      globalElapsed: const Duration(seconds: 30),
      stepElapsed: const Duration(seconds: 5),
      paused: true,
      savedAt: DateTime(2026),
      stepActualDurations: <Duration>[
        const Duration(seconds: 25),
        Duration.zero,
      ],
    );
    final state = SessionProgressState(
      training: _training(),
      checkpoint: checkpoint,
    );

    expect(state.restoredFromCheckpoint, isTrue);
    expect(state.currentIndex, 1);
    expect(state.completed, <bool>[true, false]);
    expect(state.stepActualDurations, <Duration>[
      const Duration(seconds: 25),
      Duration.zero,
    ]);
  });

  test('un checkpoint incompatible est ignoré', () {
    final checkpoint = SessionCheckpoint(
      trainingId: 'training',
      currentIndex: 0,
      completed: <bool>[true],
      globalElapsed: const Duration(seconds: 30),
      stepElapsed: const Duration(seconds: 5),
      paused: false,
      savedAt: DateTime(2026),
      stepActualDurations: <Duration>[const Duration(seconds: 25)],
    );
    final state = SessionProgressState(
      training: _training(),
      checkpoint: checkpoint,
    );

    expect(state.restoredFromCheckpoint, isFalse);
    expect(state.currentIndex, 0);
    expect(state.completed, <bool>[false, false]);
  });

  test(
    'terminer le dernier exercice avec des étapes manquantes demande une revue',
    () {
      final state = SessionProgressState(training: _training());
      state.jumpTo(1);

      expect(state.completeCurrentStep(), SessionStepCompletion.needsReview);
      expect(state.pendingIncompleteReview, isTrue);
      expect(state.allCompleted, isFalse);

      state.jumpTo(0);
      expect(state.pendingIncompleteReview, isFalse);
    },
  );
}

Training _training() => Training(
  id: 'training',
  name: 'Séance',
  createdAt: DateTime(2026),
  groups: <ExerciseGroup>[
    ExerciseGroup(
      id: 'group',
      name: 'Groupe',
      items: <TrainingItem>[
        TrainingItem(
          type: ItemType.exercise,
          name: 'Exercice 1',
          duration: const Duration(seconds: 10),
        ),
        TrainingItem(
          type: ItemType.exercise,
          name: 'Exercice 2',
          duration: const Duration(seconds: 10),
        ),
      ],
    ),
  ],
);
