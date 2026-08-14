import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/training.dart';
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
