import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/notification_sound.dart';
import 'package:rep_timer/models/session_step.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/session_countdown_scheduler.dart';
import 'package:rep_timer/services/session_notification_snapshot.dart';
import 'package:rep_timer/services/step_end_notification_service.dart';

void main() {
  late NotificationMode mode;
  late SessionNotificationSnapshot snapshot;
  late _FakeSchedule schedule;
  late _FakeStepEndNotifier notifier;
  late int stepEnds;
  late SessionCountdownScheduler countdown;

  setUp(() {
    mode = NotificationMode.sound;
    snapshot = _snapshot();
    schedule = _FakeSchedule();
    notifier = _FakeStepEndNotifier();
    stepEnds = 0;
    countdown = SessionCountdownScheduler(
      modeProvider: () => mode,
      snapshotProvider: () => snapshot,
      stepTokenProvider: _token,
      stepEndNotifier: notifier,
      notificationSound: _sound,
      onTimedStepEnded: () => stepEnds++,
      schedule: schedule.call,
    );
  });

  test('arme et annule le compte à rebours sans attente réelle', () {
    countdown.arm();

    expect(schedule.entries, hasLength(1));
    expect(schedule.entries.single.delay, const Duration(milliseconds: 7600));
    expect(schedule.entries.single.cancelled, isFalse);

    countdown.cancel();

    expect(schedule.entries.single.cancelled, isTrue);
    expect(notifier.stopCalls, 1);
  });

  test('n’arme rien pendant une pause, en arrière-plan ou hors son', () {
    snapshot = _snapshot(paused: true);
    countdown.arm();
    snapshot = _snapshot(backgrounded: true);
    countdown.arm();
    snapshot = _snapshot();
    mode = NotificationMode.vibration;
    countdown.arm();

    expect(schedule.entries, isEmpty);
  });

  test('émet son, vibration et fin au plus une fois par token', () async {
    countdown.arm();
    schedule.entries.single.fire();
    schedule.entries.single.fire();
    countdown.handleSoundThreshold(_token(snapshot));

    mode = NotificationMode.vibration;
    countdown.notifyTimedStepCompletionFallback();
    countdown.notifyTimedStepCompletionFallback();
    countdown.handleTimedStepEnded(_token(snapshot), mode);
    countdown.handleTimedStepEnded(_token(snapshot), mode);
    await _flush();

    expect(notifier.soundCalls, 1);
    expect(notifier.vibrationCalls, 1);
    expect(stepEnds, 1);
  });

  test('ignore les anciens tokens et libère ses ressources une fois', () {
    countdown.arm();
    countdown.handleSoundThreshold('ancien-token');
    countdown.handleTimedStepEnded('ancien-token', NotificationMode.sound);
    countdown.dispose();
    countdown.dispose();
    schedule.entries.single.fire();

    expect(notifier.soundCalls, 0);
    expect(stepEnds, 0);
    expect(notifier.disposeCalls, 1);
    expect(schedule.entries.single.cancelled, isTrue);
  });
}

const _sound = NotificationSound(
  sequenceAsset: 'sound.ogg',
  goOffset: Duration(milliseconds: 2400),
);

String _token(SessionNotificationSnapshot value) =>
    'session:${value.currentIndex}:${value.stepOccurrence}';

SessionNotificationSnapshot _snapshot({
  bool paused = false,
  bool backgrounded = false,
}) => SessionNotificationSnapshot(
  currentStep: SessionStep(
    group: ExerciseGroup(id: 'group', name: 'Groupe', items: const []),
    roundIndex: 1,
    totalRounds: 1,
    item: TrainingItem(
      type: ItemType.exercise,
      name: 'Exercice',
      duration: const Duration(seconds: 10),
    ),
  ),
  nextStep: null,
  currentIndex: 1,
  stepOccurrence: 3,
  stepElapsed: Duration.zero,
  paused: paused,
  finished: false,
  isAppBackgrounded: backgrounded,
);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _FakeSchedule {
  final entries = <_Scheduled>[];

  void Function() call(Duration delay, void Function() callback) {
    final entry = _Scheduled(delay, callback);
    entries.add(entry);
    return () => entry.cancelled = true;
  }
}

class _Scheduled {
  _Scheduled(this.delay, this.callback);

  final Duration delay;
  final void Function() callback;
  bool cancelled = false;

  void fire() {
    if (!cancelled) callback();
  }
}

class _FakeStepEndNotifier implements StepEndNotifier {
  int soundCalls = 0;
  int vibrationCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;

  @override
  Future<void> preload(NotificationSound sound) async {}

  @override
  Future<void> playCountdown(NotificationSound sound) async => soundCalls++;

  @override
  Future<void> stopCountdown() async => stopCalls++;

  @override
  Future<void> vibrate() async => vibrationCalls++;

  @override
  void dispose() => disposeCalls++;
}
