import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/session_checkpoint.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/session_controller.dart';

import '../support/timed_session_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final scenario in <(NotificationMode, int, int)>[
    (NotificationMode.sound, 4, 0),
    (NotificationMode.vibration, 0, 4),
    (NotificationMode.none, 0, 0),
  ]) {
    test('signale 3/2/1/départ en mode ${scenario.$1.name}', () async {
      final harness = TimedSessionHarness(_training(), mode: scenario.$1);
      final controller = harness.build(countdownSeconds: 5);
      addTearDown(controller.dispose);
      await _flush();

      expect(controller.preparing, isTrue);
      expect(controller.phase, SessionExecutionPhase.preparing);
      expect(harness.checkpoints.saved, isEmpty);
      expect(harness.foreground.pinCalls, 0);
      for (var second = 0; second < 5; second++) {
        harness.advance(const Duration(seconds: 1));
      }
      await _flush();

      expect(controller.preparing, isFalse);
      expect(controller.phase, SessionExecutionPhase.running);
      expect(controller.globalElapsed, Duration.zero);
      expect(controller.stepElapsed, Duration.zero);
      expect(harness.notifier.soundCalls, scenario.$2);
      expect(harness.notifier.vibrationCalls, scenario.$3);
      expect(harness.checkpoints.saved, hasLength(1));
      expect(harness.foreground.pinCalls, 1);
    });
  }

  test('arrière-plan met en pause et le retour attend une reprise', () {
    final harness = TimedSessionHarness(_training());
    final controller = harness.build(countdownSeconds: 5);
    addTearDown(controller.dispose);

    harness.advance(const Duration(milliseconds: 400));
    controller.handleAppBackgrounded();
    harness.advance(const Duration(seconds: 10));
    controller.handleAppResumed();

    expect(controller.preparing, isTrue);
    expect(controller.paused, isTrue);
    expect(controller.preparationSeconds, 5);

    controller.togglePause();
    harness.advance(const Duration(milliseconds: 600));
    expect(controller.preparationSeconds, 4);
  });

  test('Suivant passe une préparation active ou pausée sans double départ', () {
    final harness = TimedSessionHarness(_training());
    final controller = harness.build(countdownSeconds: 15);
    addTearDown(controller.dispose);

    controller.togglePause();
    controller
      ..skipPreparation()
      ..skipPreparation();

    expect(controller.preparing, isFalse);
    expect(controller.paused, isFalse);
    expect(controller.globalElapsed, Duration.zero);
    expect(harness.checkpoints.saved, hasLength(1));
  });

  test('une reprise de checkpoint ignore toujours la préparation', () {
    final training = _training();
    final harness = TimedSessionHarness(training);
    final checkpoint = SessionCheckpoint(
      trainingId: training.id,
      currentIndex: 0,
      completed: [false],
      globalElapsed: const Duration(seconds: 8),
      stepElapsed: const Duration(seconds: 3),
      paused: true,
      savedAt: harness.time,
      stepActualDurations: [Duration.zero],
    );
    final controller = harness.build(
      checkpoint: checkpoint,
      countdownSeconds: 15,
    );
    addTearDown(controller.dispose);

    expect(controller.preparing, isFalse);
    expect(controller.paused, isTrue);
    expect(controller.globalElapsed, const Duration(seconds: 8));
  });

  test('zéro et les valeurs hors bornes démarrent immédiatement', () {
    for (final value in [-1, 0, 16]) {
      final harness = TimedSessionHarness(_training());
      final controller = harness.build(countdownSeconds: value);
      expect(controller.phase, SessionExecutionPhase.running);
      controller.dispose();
    }
  });

  test('le temps de préparation est exclu de l’historique', () async {
    final harness = TimedSessionHarness(_training());
    final controller = harness.build(countdownSeconds: 5);
    addTearDown(controller.dispose);

    harness.advance(const Duration(seconds: 5));
    await controller.finishSession(earlyExit: true);

    expect(harness.history.entries, hasLength(1));
    expect(harness.history.entries.single.totalDuration, Duration.zero);
    expect(
      harness.history.entries.single.steps.single.actualDuration,
      Duration.zero,
    );
    expect(controller.phase, SessionExecutionPhase.finished);
  });
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

Training _training() => Training(
  id: 'training',
  name: 'Séance',
  groups: [
    ExerciseGroup(
      id: 'group',
      name: 'Groupe',
      items: [
        TrainingItem(
          type: ItemType.exercise,
          name: 'Effort',
          duration: const Duration(seconds: 30),
        ),
      ],
    ),
  ],
  createdAt: DateTime(2026),
);
