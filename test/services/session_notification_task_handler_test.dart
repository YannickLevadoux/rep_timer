import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/services/session_notification_platform.dart';
import 'package:rep_timer/services/session_notification_protocol.dart';
import 'package:rep_timer/services/session_notification_task_handler.dart';
import 'package:rep_timer/services/step_end_trigger_scheduler.dart';

void main() {
  test('démarre et répète sans état sans effet de bord', () async {
    final platform = _FakeTaskPlatform();
    final handler = SessionNotificationTaskHandler(platform: platform);

    await handler.onStart(DateTime(2026), TaskStarter.developer);
    handler.onRepeatEvent(DateTime(2026));

    expect(platform.notifications, isEmpty);
    expect(platform.mainData, isEmpty);
  });

  test('rejette un message invalide', () async {
    final platform = _FakeTaskPlatform();
    final handler = SessionNotificationTaskHandler(platform: platform);

    handler.onReceiveData(<String, Object>{'stepLabel': 'incomplet'});
    await _flush();

    expect(platform.notifications, isEmpty);
  });

  test('reçoit un point de référence et construit le contenu actif', () async {
    final now = DateTime.utc(2026, 8, 11, 10);
    final platform = _FakeTaskPlatform();
    final handler = SessionNotificationTaskHandler(
      platform: platform,
      now: () => now,
    );

    handler.onReceiveData(_pin(now: now).toWire());
    await _flush();

    final notification = platform.notifications.single;
    expect(notification.title, '00:05 — Groupe - Squats');
    expect(notification.text, 'Suivant : Repos');
    expect(notification.iconMetadataName, 'session_notification_icon_play');
    expect(notification.buttonId, 'pause');
    expect(notification.buttonLabel, 'Pause');
  });

  test(
    'affiche Reprendre et l’icône pause lorsque la séance est en pause',
    () async {
      final now = DateTime.utc(2026, 8, 11, 10);
      final platform = _FakeTaskPlatform();
      final handler = SessionNotificationTaskHandler(
        platform: platform,
        now: () => now,
      );

      handler.onReceiveData(_pin(now: now, isPlaying: false).toWire());
      await _flush();

      expect(
        platform.notifications.single.iconMetadataName,
        'session_notification_icon_pause',
      );
      expect(platform.notifications.single.buttonLabel, 'Reprendre');
    },
  );

  test('met à jour le chronomètre lors des répétitions', () async {
    var now = DateTime.utc(2026, 8, 11, 10);
    final platform = _FakeTaskPlatform();
    final handler = SessionNotificationTaskHandler(
      platform: platform,
      now: () => now,
    );
    handler.onReceiveData(_pin(now: now, isCountingDown: false).toWire());
    await _flush();

    now = now.add(const Duration(seconds: 2));
    handler.onRepeatEvent(now);
    await _flush();

    expect(platform.notifications.last.title, '00:07 — Groupe - Squats');
  });

  test('transmet les seuils sans doublon lors des réévaluations', () async {
    var now = DateTime.utc(2026, 8, 11, 10);
    final platform = _FakeTaskPlatform();
    final timers = _FakeTimers();
    final handler = SessionNotificationTaskHandler(
      platform: platform,
      now: () => now,
      schedule: timers.schedule,
    );
    handler.onReceiveData(_pin(now: now).toWire());
    await _flush();

    now = now.add(const Duration(milliseconds: 2600));
    handler.onRepeatEvent(now);
    handler.onRepeatEvent(now);
    now = now.add(const Duration(milliseconds: 2400));
    handler.onRepeatEvent(now);
    handler.onRepeatEvent(now);
    await _flush();

    final events = platform.mainData
        .map(SessionNotificationEvent.fromWire)
        .whereType<SessionNotificationEvent>()
        .toList();
    expect(events.whereType<SessionSoundThresholdReached>(), hasLength(1));
    expect(events.whereType<SessionTimedStepEnded>(), hasLength(1));
    expect(
      (events.whereType<SessionTimedStepEnded>().single).notificationMode,
      NotificationMode.sound,
    );
  });

  test('gère le bouton connu, ignore l’identifiant inconnu et ouvre l’app', () {
    final platform = _FakeTaskPlatform();
    final handler = SessionNotificationTaskHandler(platform: platform);

    handler.onNotificationButtonPressed('pause');
    handler.onNotificationButtonPressed('inconnu');
    handler.onNotificationPressed();

    expect(platform.mainData, <Object>['pause']);
    expect(platform.launchCalls, 1);
  });

  test('absorbe les erreurs de notification, événement et ouverture', () async {
    final now = DateTime.utc(2026, 8, 11, 10);
    final platform = _FakeTaskPlatform(throwOnCalls: true);
    final handler = SessionNotificationTaskHandler(
      platform: platform,
      now: () => now,
    );

    handler.onReceiveData(_pin(now: now).toWire());
    handler.onNotificationButtonPressed('pause');
    handler.onNotificationPressed();
    await _flush();
  });

  test(
    'détruit le handler et libère les déclenchements du scheduler',
    () async {
      final now = DateTime.utc(2026, 8, 11, 10);
      final timers = _FakeTimers();
      final handler = SessionNotificationTaskHandler(
        platform: _FakeTaskPlatform(),
        now: () => now,
        schedule: timers.schedule,
      );
      handler.onReceiveData(_pin(now: now).toWire());

      await handler.onDestroy(now, false);

      expect(timers.triggers, isNotEmpty);
      expect(timers.triggers.every((trigger) => trigger.cancelled), isTrue);
    },
  );
}

SessionNotificationPinData _pin({
  required DateTime now,
  bool isPlaying = true,
  bool isCountingDown = true,
}) => SessionNotificationPinData(
  stepLabel: 'Groupe - Squats',
  nextStepLabel: 'Suivant : Repos',
  stepToken: 'step-1',
  notificationMode: NotificationMode.sound,
  isPlaying: isPlaying,
  isCountingDown: isCountingDown,
  baseMilliseconds: 5000,
  pinEpochMillis: now.millisecondsSinceEpoch,
  soundGoOffsetMilliseconds: 2400,
);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _FakeTaskPlatform implements SessionNotificationTaskPlatform {
  _FakeTaskPlatform({this.throwOnCalls = false});

  final bool throwOnCalls;
  final notifications = <SessionForegroundNotification>[];
  final mainData = <Object>[];
  int launchCalls = 0;
  TaskHandler? handler;

  @override
  void setTaskHandler(TaskHandler handler) => this.handler = handler;

  @override
  void sendDataToMain(Object data) {
    if (throwOnCalls) throw StateError('send');
    mainData.add(data);
  }

  @override
  Future<void> updateNotification(
    SessionForegroundNotification notification,
  ) async {
    if (throwOnCalls) throw StateError('update');
    notifications.add(notification);
  }

  @override
  void launchApp() {
    if (throwOnCalls) throw StateError('launch');
    launchCalls++;
  }
}

class _FakeTimers {
  final triggers = <_FakeTrigger>[];

  CancelScheduledTrigger schedule(Duration delay, void Function() callback) {
    final trigger = _FakeTrigger();
    triggers.add(trigger);
    return () => trigger.cancelled = true;
  }
}

class _FakeTrigger {
  bool cancelled = false;
}
