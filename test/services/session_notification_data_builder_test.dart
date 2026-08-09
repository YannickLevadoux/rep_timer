import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/session_step.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/session_notification_data_builder.dart';
import 'package:rep_timer/services/session_notification_snapshot.dart';

void main() {
  final now = DateTime.utc(2026, 8, 9, 10, 30);
  final builder = SessionNotificationDataBuilder(
    sessionToken: 'session',
    soundGoOffset: const Duration(milliseconds: 2400),
    now: () => now,
  );

  test('construit le payload d’une durée fixe', () {
    final data = builder.build(
      snapshot: _snapshot(
        currentStep: _step(
          name: 'Squats',
          duration: const Duration(seconds: 10),
        ),
        nextStep: _step(name: 'Gainage', isFreeDuration: true),
        elapsed: const Duration(milliseconds: 3500),
      ),
      mode: NotificationMode.sound,
    );

    expect(data.stepLabel, 'Squats');
    expect(data.nextStepLabel, 'Suivant : Groupe - Gainage');
    expect(data.stepToken, 'session:2:4');
    expect(data.notificationMode, NotificationMode.sound);
    expect(data.isPlaying, isTrue);
    expect(data.isCountingDown, isTrue);
    expect(data.baseMilliseconds, 6500);
    expect(data.pinEpochMillis, now.millisecondsSinceEpoch);
    expect(data.soundGoOffsetMilliseconds, 2400);
  });

  test('construit le payload d’une durée libre', () {
    final data = builder.build(
      snapshot: _snapshot(
        currentStep: _step(name: 'Gainage', isFreeDuration: true),
        elapsed: const Duration(milliseconds: 4200),
      ),
      mode: NotificationMode.none,
    );

    expect(data.isCountingDown, isFalse);
    expect(data.baseMilliseconds, 4200);
    expect(data.nextStepLabel, 'Fin de la séance');
  });

  test('construit le payload d’une pause mise en pause et borne à zéro', () {
    final data = builder.build(
      snapshot: _snapshot(
        currentStep: _step(
          name: '',
          type: ItemType.rest,
          duration: const Duration(seconds: 2),
        ),
        elapsed: const Duration(seconds: 3),
        paused: true,
      ),
      mode: NotificationMode.vibration,
    );

    expect(data.stepLabel, 'Pause');
    expect(data.nextStepLabel, 'Fin de la séance');
    expect(data.isPlaying, isFalse);
    expect(data.baseMilliseconds, 0);
  });
}

SessionNotificationSnapshot _snapshot({
  required SessionStep currentStep,
  SessionStep? nextStep,
  Duration elapsed = Duration.zero,
  bool paused = false,
}) => SessionNotificationSnapshot(
  currentStep: currentStep,
  nextStep: nextStep,
  currentIndex: 2,
  stepOccurrence: 4,
  stepElapsed: elapsed,
  paused: paused,
  finished: false,
  isAppBackgrounded: false,
);

SessionStep _step({
  required String name,
  ItemType type = ItemType.exercise,
  Duration? duration,
  bool isFreeDuration = false,
}) => SessionStep(
  group: ExerciseGroup(id: 'group', name: 'Groupe', items: const []),
  roundIndex: 1,
  totalRounds: 1,
  item: TrainingItem(
    type: type,
    name: name,
    duration: duration,
    isFreeDuration: isFreeDuration,
  ),
);
