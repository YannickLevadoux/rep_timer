import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/services/session_notification_protocol.dart';
import 'package:rep_timer/services/step_end_trigger_scheduler.dart';

void main() {
  test('émet le seuil sonore et la fin une seule fois par étape', () {
    var now = DateTime(2026);
    final timers = _FakeTriggerTimers();
    final events = <SessionNotificationEvent>[];
    final scheduler = StepEndTriggerScheduler(
      onEvent: events.add,
      now: () => now,
      schedule: timers.schedule,
    );

    scheduler.update(_pin(now: now, token: 'step-1'));

    expect(timers.activeDelays, <Duration>[
      const Duration(milliseconds: 2600),
      const Duration(seconds: 5),
    ]);

    now = now.add(const Duration(milliseconds: 2600));
    timers.fireNext();
    scheduler.evaluate();

    now = now.add(const Duration(milliseconds: 2400));
    timers.fireNext();
    scheduler.evaluate();
    scheduler.evaluate();

    expect(events.whereType<SessionSoundThresholdReached>(), hasLength(1));
    expect(events.whereType<SessionTimedStepEnded>(), hasLength(1));
  });

  test('une resynchronisation réarme les timers sans réémettre le son', () {
    var now = DateTime(2026);
    final timers = _FakeTriggerTimers();
    final events = <SessionNotificationEvent>[];
    final scheduler = StepEndTriggerScheduler(
      onEvent: events.add,
      now: () => now,
      schedule: timers.schedule,
    );

    scheduler.update(_pin(now: now, token: 'step-1'));
    now = now.add(const Duration(milliseconds: 2600));
    timers.fireNext();

    scheduler.update(_pin(now: now, token: 'step-1', baseMilliseconds: 2400));

    expect(events.whereType<SessionSoundThresholdReached>(), hasLength(1));
    expect(timers.activeDelays, <Duration>[const Duration(milliseconds: 2400)]);

    now = now.add(const Duration(milliseconds: 2400));
    timers.fireNext();
    scheduler.evaluate();

    expect(events.whereType<SessionSoundThresholdReached>(), hasLength(1));
    expect(events.whereType<SessionTimedStepEnded>(), hasLength(1));
  });

  test(
    'un seuil déjà dépassé lors du premier armement ne joue pas en retard',
    () {
      var now = DateTime(2026);
      final timers = _FakeTriggerTimers();
      final events = <SessionNotificationEvent>[];
      final scheduler = StepEndTriggerScheduler(
        onEvent: events.add,
        now: () => now,
        schedule: timers.schedule,
      );

      scheduler.update(_pin(now: now, token: 'step-1', baseMilliseconds: 1000));
      expect(timers.activeDelays, <Duration>[const Duration(seconds: 1)]);

      now = now.add(const Duration(seconds: 1));
      timers.fireNext();
      scheduler.evaluate();

      expect(events.whereType<SessionSoundThresholdReached>(), isEmpty);
      expect(events.whereType<SessionTimedStepEnded>(), hasLength(1));
    },
  );

  test('la pause annule les déclenchements jusqu’à la reprise', () {
    var now = DateTime(2026);
    final timers = _FakeTriggerTimers();
    final events = <SessionNotificationEvent>[];
    final scheduler = StepEndTriggerScheduler(
      onEvent: events.add,
      now: () => now,
      schedule: timers.schedule,
    );

    scheduler.update(_pin(now: now, token: 'step-1'));
    scheduler.update(_pin(now: now, token: 'step-1', isPlaying: false));
    expect(timers.activeDelays, isEmpty);

    now = now.add(const Duration(seconds: 10));
    scheduler.evaluate();
    expect(events, isEmpty);

    scheduler.update(_pin(now: now, token: 'step-1', baseMilliseconds: 5000));
    expect(timers.activeDelays, hasLength(2));
  });

  test('deux tokens successifs ont chacun leurs propres déclenchements', () {
    var now = DateTime(2026);
    final timers = _FakeTriggerTimers();
    final events = <SessionNotificationEvent>[];
    final scheduler = StepEndTriggerScheduler(
      onEvent: events.add,
      now: () => now,
      schedule: timers.schedule,
    );

    scheduler.update(_pin(now: now, token: 'step-1'));
    now = now.add(const Duration(seconds: 5));
    scheduler.evaluate();

    scheduler.update(_pin(now: now, token: 'step-2'));
    now = now.add(const Duration(seconds: 5));
    scheduler.evaluate();

    expect(
      events.whereType<SessionTimedStepEnded>().map((event) => event.stepToken),
      <String>['step-1', 'step-2'],
    );
  });
}

SessionNotificationPinData _pin({
  required DateTime now,
  required String token,
  int baseMilliseconds = 5000,
  bool isPlaying = true,
}) => SessionNotificationPinData(
  stepLabel: 'Exercice',
  nextStepLabel: 'Suivant : Groupe - Exercice 2',
  stepToken: token,
  notificationMode: NotificationMode.sound,
  isPlaying: isPlaying,
  isCountingDown: true,
  baseMilliseconds: baseMilliseconds,
  pinEpochMillis: now.millisecondsSinceEpoch,
  soundGoOffsetMilliseconds: 2400,
);

class _FakeTriggerTimers {
  final List<_FakeTrigger> _triggers = <_FakeTrigger>[];

  CancelScheduledTrigger schedule(Duration delay, void Function() callback) {
    final trigger = _FakeTrigger(delay, callback);
    _triggers.add(trigger);
    return () => trigger.cancelled = true;
  }

  List<Duration> get activeDelays => _triggers
      .where((trigger) => !trigger.cancelled && !trigger.fired)
      .map((trigger) => trigger.delay)
      .toList();

  void fireNext() {
    final trigger = _triggers.firstWhere(
      (candidate) => !candidate.cancelled && !candidate.fired,
    );
    trigger.fired = true;
    trigger.callback();
  }
}

class _FakeTrigger {
  _FakeTrigger(this.delay, this.callback);

  final Duration delay;
  final void Function() callback;
  bool cancelled = false;
  bool fired = false;
}
