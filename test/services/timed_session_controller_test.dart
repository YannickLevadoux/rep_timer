import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/models/training_item.dart';

import '../support/timed_session_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pause et reprise suspendent le tour et le délai AMRAP', () async {
    final harness = TimedSessionHarness(_amrapTraining());
    final controller = harness.build();
    addTearDown(controller.dispose);
    await _flush();

    harness.advance(const Duration(seconds: 5));
    expect(controller.recordAmrapLap(), isTrue);
    harness.advance(const Duration(seconds: 1));
    expect(controller.amrap!.buttonDelayRemaining, const Duration(seconds: 1));
    controller.togglePause();
    harness.advance(const Duration(seconds: 20));
    expect(controller.amrap!.currentLapDuration, const Duration(seconds: 1));
    expect(controller.amrap!.buttonDelayRemaining, const Duration(seconds: 1));

    controller.togglePause();
    harness.advance(const Duration(seconds: 1));
    expect(controller.amrap!.currentLapDuration, const Duration(seconds: 2));
    expect(controller.amrap!.buttonDelayRemaining, Duration.zero);
  });

  test('checkpoint AMRAP restaure tours, tour courant et délai', () async {
    final harness = TimedSessionHarness(_amrapTraining());
    final controller = harness.build();
    await _flush();
    harness.advance(const Duration(seconds: 10));
    controller.recordAmrapLap();
    harness.advance(const Duration(seconds: 1));
    await _flush();
    final checkpoint = harness.checkpoints.saved.last;
    controller.dispose();

    final restored = harness.build(checkpoint: checkpoint);
    addTearDown(restored.dispose);
    expect(restored.amrap!.completedLapDurations, [
      const Duration(seconds: 10),
    ]);
    expect(restored.amrap!.currentLapDuration, const Duration(seconds: 1));
    expect(restored.amrap!.buttonDelayRemaining, const Duration(seconds: 1));
  });

  test('navigation conserve puis redémarre explicitement une tentative', () {
    final harness = TimedSessionHarness(_amrapTraining());
    final controller = harness.build();
    addTearDown(controller.dispose);
    harness.advance(const Duration(seconds: 12));

    expect(controller.goToNext(), isTrue);
    expect(controller.completed.first, isFalse);
    expect(controller.requiresAmrapRestart(0), isTrue);
    expect(controller.jumpToStep(0), isFalse);
    expect(controller.jumpToStep(0, restartAmrap: true), isTrue);
    expect(controller.amrap!.activeRemaining, const Duration(minutes: 1));
    expect(controller.amrap!.completedLapDurations, isEmpty);
  });

  test(
    'expiration AMRAP alimente le même historique avec son partiel',
    () async {
      final harness = TimedSessionHarness(_amrapTraining());
      final controller = harness.build();
      addTearDown(controller.dispose);
      harness.advance(const Duration(seconds: 20));
      controller.recordAmrapLap();
      harness.advance(const Duration(seconds: 40));
      expect(controller.currentIndex, 1);
      await controller.finishSession(earlyExit: true);

      final amrap = harness.history.entries.single.steps.first.amrap!;
      expect(amrap.completedLapDurations, [const Duration(seconds: 20)]);
      expect(amrap.partialLapDuration, const Duration(seconds: 40));
      expect(amrap.completed, isTrue);
    },
  );

  test(
    'EMOM avance à zéro, vibre et remet une minute revisitée à faire',
    () async {
      final harness = TimedSessionHarness(
        _emomTraining(),
        mode: NotificationMode.vibration,
      );
      final controller = harness.build();
      addTearDown(controller.dispose);
      await _flush();

      harness.advance(const Duration(minutes: 1));
      await _flush();
      expect(controller.currentIndex, 1);
      expect(controller.completed, [true, false]);
      expect(harness.notifier.vibrationCalls, 1);

      expect(controller.goToPrevious(), isTrue);
      expect(controller.completed, [false, false]);
      expect(controller.stepElapsed, Duration.zero);
    },
  );

  test(
    'Tabata notifie chaque phase, suspend les chronos et écrit l’historique',
    () async {
      final harness = TimedSessionHarness(
        _tabataTraining(),
        mode: NotificationMode.vibration,
      );
      final controller = harness.build();
      addTearDown(controller.dispose);
      await _flush();

      expect(controller.steps, hasLength(3));
      expect(controller.currentStep.item.name, 'Effort');
      expect(controller.currentStep.roundIndex, 1);

      harness.advance(const Duration(seconds: 20));
      await _flush();
      expect(controller.currentStep.item.type, ItemType.rest);
      expect(harness.notifier.vibrationCalls, 1);

      controller.togglePause();
      harness.advance(const Duration(seconds: 30));
      expect(controller.stepElapsed, Duration.zero);
      controller.togglePause();
      harness.advance(const Duration(seconds: 10));
      await _flush();
      expect(controller.currentStep.item.name, 'Effort');
      expect(controller.currentStep.roundIndex, 2);
      expect(harness.notifier.vibrationCalls, 2);

      harness.advance(const Duration(seconds: 20));
      await _flush();
      await _flush();
      expect(controller.finished, isTrue);
      expect(harness.notifier.vibrationCalls, 3);
      final history = harness.history.entries.single;
      expect(history.status, TrainingSessionStatus.completed);
      expect(history.steps.map((step) => step.itemType), [
        ItemType.exercise,
        ItemType.rest,
        ItemType.exercise,
      ]);
      expect(history.steps.map((step) => step.actualDuration.inSeconds), [
        20,
        10,
        20,
      ]);
    },
  );

  test('checkpoint Tabata restaure phase, cycle et temps restant', () async {
    final harness = TimedSessionHarness(_tabataTraining());
    final controller = harness.build();
    await _flush();
    harness.advance(const Duration(seconds: 20));
    harness.advance(const Duration(seconds: 4));
    controller.togglePause();
    await _flush();
    final checkpoint = harness.checkpoints.saved.last;
    controller.dispose();

    final restored = harness.build(checkpoint: checkpoint);
    addTearDown(restored.dispose);
    expect(restored.paused, isTrue);
    expect(restored.currentIndex, 1);
    expect(restored.currentStep.item.type, ItemType.rest);
    expect(restored.currentStep.roundIndex, 1);
    expect(restored.currentStep.totalRounds, 2);
    expect(restored.stepElapsed, const Duration(seconds: 4));

    restored.togglePause();
    harness.advance(const Duration(seconds: 6));
    expect(restored.currentStep.item.name, 'Effort');
    expect(restored.currentStep.roundIndex, 2);
  });

  test(
    'la pause finale Tabata personnalisée notifie avant le groupe suivant',
    () async {
      final harness = TimedSessionHarness(
        _tabataTraining(followed: true, finalRestSeconds: 17),
        mode: NotificationMode.vibration,
      );
      final controller = harness.build();
      addTearDown(controller.dispose);
      await _flush();

      for (final seconds in [20, 10, 20, 17]) {
        harness.advance(Duration(seconds: seconds));
        await _flush();
      }

      expect(controller.currentStep.group.id, 'next');
      expect(controller.steps[3].item.duration, const Duration(seconds: 17));
      expect(harness.notifier.vibrationCalls, 4);
    },
  );
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

Training _amrapTraining() => Training(
  id: 'training',
  name: 'Séance',
  groups: [
    ExerciseGroup.amrap(id: 'amrap')
      ..items.single.duration = const Duration(minutes: 1),
    ExerciseGroup(
      id: 'next',
      name: 'Suite',
      items: [
        TrainingItem(type: ItemType.exercise, name: 'Squats', repetitions: 10),
      ],
    ),
  ],
  createdAt: DateTime(2026),
);

Training _emomTraining() => Training(
  id: 'emom-training',
  name: 'EMOM',
  groups: [ExerciseGroup.emom(id: 'emom')..rounds = 2],
  createdAt: DateTime(2026),
);

Training _tabataTraining({bool followed = false, int? finalRestSeconds}) {
  final tabata = ExerciseGroup.tabata(id: 'tabata')..rounds = 2;
  if (finalRestSeconds != null) {
    tabata.finalRestDuration = Duration(seconds: finalRestSeconds);
  }
  return Training(
    id: 'tabata-training',
    name: 'Tabata',
    groups: [
      tabata,
      if (followed)
        ExerciseGroup(
          id: 'next',
          name: 'Suite',
          items: [
            TrainingItem(
              type: ItemType.exercise,
              name: 'Squats',
              repetitions: 10,
            ),
          ],
        ),
    ],
    createdAt: DateTime(2026),
  );
}
