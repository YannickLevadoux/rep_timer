import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/amrap_history_data.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_type.dart';
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
    expect(entry.steps.single.repetitions, isNull);
    expect(entry.steps.single.actualDuration, const Duration(seconds: 10));
    expect(checkpointStorage.clearCalls, 2);
  });

  test('la clôture conserve les répétitions résolues de chaque tour', () async {
    final historyStorage = _FakeHistoryStorage();
    final training = Training(
      id: 'variable-training',
      name: 'Variable',
      groups: [
        ExerciseGroup(
          id: 'variable-group',
          name: 'Pyramide',
          type: GroupType.variableRepetitions,
          repetitionSequence: [10, 12, 15],
          items: [
            TrainingItem(
              type: ItemType.exercise,
              name: 'Squats',
              repetitions: 5,
            ),
          ],
        ),
      ],
      createdAt: DateTime(2026),
    );
    final steps = buildSessionSteps(training);
    final service = SessionCompletionService(
      checkpointStorage: _FakeCheckpointStorage(),
      historyStorage: historyStorage,
      now: () => DateTime(2026, 2, 3),
    );

    await service.completeSession(
      training: training,
      steps: steps,
      completed: [true, true, true],
      stepActualDurations: const [
        Duration(seconds: 10),
        Duration(seconds: 12),
        Duration(seconds: 15),
      ],
      totalDuration: const Duration(seconds: 37),
      status: TrainingSessionStatus.completed,
    );

    expect(
      historyStorage.entries.single.steps.map((step) => step.repetitions),
      [10, 12, 15],
    );
  });

  test('indexe les minutes EMOM mais pas leur récupération', () async {
    final historyStorage = _FakeHistoryStorage();
    final emom = ExerciseGroup.emom(id: 'emom')
      ..rounds = 2
      ..postGroupRestDuration = const Duration(seconds: 30);
    final training = Training(
      id: 'emom-training',
      name: 'EMOM',
      groups: [
        emom,
        ExerciseGroup.amrap(id: 'amrap'),
      ],
      createdAt: DateTime(2026),
    );
    final steps = buildSessionSteps(training);
    final service = SessionCompletionService(
      checkpointStorage: _FakeCheckpointStorage(),
      historyStorage: historyStorage,
      now: () => DateTime(2026),
    );

    await service.completeSession(
      training: training,
      steps: steps,
      completed: List.filled(steps.length, true),
      stepActualDurations: steps.map((step) => step.item.duration!).toList(),
      totalDuration: const Duration(minutes: 4, seconds: 30),
      status: TrainingSessionStatus.completed,
    );

    expect(
      historyStorage.entries.single.steps.map((step) => step.emomMinuteIndex),
      [1, 2, null, null],
    );
  });

  test(
    'omet une récupération AMRAP jamais exécutée et borne sa durée',
    () async {
      final historyStorage = _FakeHistoryStorage();
      final amrap = ExerciseGroup.amrap(id: 'amrap')
        ..items.single.duration = const Duration(minutes: 1)
        ..postGroupRestDuration = const Duration(seconds: 30);
      final training = Training(
        id: 'amrap-training',
        name: 'AMRAP',
        groups: [amrap, _training().groups.single],
        createdAt: DateTime(2026),
      );
      final steps = buildSessionSteps(training);
      final service = SessionCompletionService(
        checkpointStorage: _FakeCheckpointStorage(),
        historyStorage: historyStorage,
        now: () => DateTime(2026),
      );

      await service.completeSession(
        training: training,
        steps: steps,
        completed: const [true, false, false],
        stepActualDurations: const [
          Duration(seconds: 65),
          Duration.zero,
          Duration.zero,
        ],
        totalDuration: const Duration(seconds: 65),
        status: TrainingSessionStatus.incomplete,
        amrapHistory: {
          0: AmrapHistoryData(
            configuredDuration: const Duration(minutes: 1),
            activeDuration: const Duration(minutes: 1),
            completedLapDurations: const [],
            partialLapDuration: const Duration(minutes: 1),
            completed: true,
          ),
        },
      );

      final history = historyStorage.entries.single;
      expect(history.steps, hasLength(2));
      expect(history.steps.first.actualDuration, const Duration(minutes: 1));
      expect(
        history.steps.where((step) => step.itemType == ItemType.rest),
        isEmpty,
      );
    },
  );
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
