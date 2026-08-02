import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/session_checkpoint.dart';
import 'package:rep_timer/models/session_step.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/session_checkpoint_storage.dart';
import 'package:rep_timer/services/session_completion_service.dart';
import 'package:rep_timer/services/training_history_storage.dart';

void main() {
  test('le checkpoint sauvegardé est un instantané indépendant', () async {
    final checkpointStorage = _FakeCheckpointStorage();
    final completed = <bool>[false];
    final actualDurations = <Duration>[const Duration(seconds: 4)];
    final service = SessionCompletionService(
      checkpointStorage: checkpointStorage,
      historyStorage: _FakeHistoryStorage(),
      now: () => DateTime(2026),
    );

    await service.saveCheckpoint(
      trainingId: 'training',
      currentIndex: 0,
      completed: completed,
      globalElapsed: const Duration(seconds: 8),
      stepElapsed: const Duration(seconds: 4),
      paused: false,
      stepActualDurations: actualDurations,
    );
    completed[0] = true;
    actualDurations[0] = const Duration(seconds: 20);

    expect(checkpointStorage.saved!.completed, <bool>[false]);
    expect(checkpointStorage.saved!.stepActualDurations, <Duration>[
      const Duration(seconds: 4),
    ]);
    expect(checkpointStorage.saved!.savedAt, DateTime(2026));
  });

  test('la clôture construit une seule entrée d’historique', () async {
    final checkpointStorage = _FakeCheckpointStorage();
    final historyStorage = _FakeHistoryStorage();
    final training = _training();
    final steps = buildSessionSteps(training);
    final service = SessionCompletionService(
      checkpointStorage: checkpointStorage,
      historyStorage: historyStorage,
      now: () => DateTime(2026, 2, 3),
    );

    for (var i = 0; i < 2; i++) {
      await service.completeSession(
        training: training,
        steps: steps,
        completed: <bool>[true],
        stepActualDurations: <Duration>[const Duration(seconds: 10)],
        totalDuration: const Duration(seconds: 10),
        status: TrainingSessionStatus.completed,
      );
    }

    expect(historyStorage.entries, hasLength(1));
    final entry = historyStorage.entries.single;
    expect(entry.trainingName, 'Séance');
    expect(entry.status, TrainingSessionStatus.completed);
    expect(entry.steps.single.groupName, 'Groupe');
    expect(entry.steps.single.itemName, 'Exercice');
    expect(entry.steps.single.actualDuration, const Duration(seconds: 10));
    expect(checkpointStorage.clearCalls, 2);
  });
}

Training _training() {
  final group = ExerciseGroup(
    id: 'group',
    name: 'Groupe',
    items: <TrainingItem>[
      TrainingItem(
        type: ItemType.exercise,
        name: 'Exercice',
        duration: const Duration(seconds: 10),
      ),
    ],
  );
  return Training(
    id: 'training',
    name: 'Séance',
    groups: <ExerciseGroup>[group],
    createdAt: DateTime(2026),
  );
}

class _FakeCheckpointStorage extends SessionCheckpointStorage {
  SessionCheckpoint? saved;
  int clearCalls = 0;

  @override
  Future<void> saveCheckpoint(SessionCheckpoint checkpoint) async {
    saved = checkpoint;
  }

  @override
  Future<void> clearCheckpoint() async {
    clearCalls++;
  }
}

class _FakeHistoryStorage extends TrainingHistoryStorage {
  final List<TrainingHistoryEntry> entries = <TrainingHistoryEntry>[];

  @override
  Future<void> addEntry(TrainingHistoryEntry entry) async {
    entries.add(entry);
  }
}
