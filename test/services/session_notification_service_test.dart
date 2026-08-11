import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/services/session_notification_permission_service.dart';
import 'package:rep_timer/services/session_notification_platform.dart';
import 'package:rep_timer/services/session_notification_protocol.dart';
import 'package:rep_timer/services/session_notification_service.dart';
import 'package:rep_timer/services/session_notification_task_handler.dart';

void main() {
  test('initialise le port de communication', () {
    final platform = _FakeServicePlatform();

    SessionNotificationService.initCommunicationPort(platform: platform);

    expect(platform.initCalls, 1);
  });

  test(
    'un pin initialise les permissions et enregistre le callback une fois',
    () async {
      final platform = _FakeServicePlatform(defaultRunning: true);
      final permissions = _FakePermissionPlatform();
      final service = _service(platform, permissions);

      await service.pin(
        data: _pin('step-1'),
        onPausePressed: () {},
        onSoundThreshold: (_) {},
        onTimedStepEnded: (_, _) {},
      );
      await service.pin(
        data: _pin('step-2'),
        onPausePressed: () {},
        onSoundThreshold: (_) {},
        onTimedStepEnded: (_, _) {},
      );

      expect(permissions.initializeCalls, 2);
      expect(platform.addCallbackCalls, 1);
    },
  );

  test(
    'démarre avec le contenu initial puis transmet le point de référence',
    () async {
      final platform = _FakeServicePlatform();
      final service = _service(platform, _FakePermissionPlatform());
      final data = _pin('step-1');

      await service.pin(
        data: data,
        onPausePressed: () {},
        onSoundThreshold: (_) {},
        onTimedStepEnded: (_, _) {},
      );

      expect(platform.startCalls, 1);
      expect(platform.serviceId, 4200);
      expect(platform.startCallback, sessionNotificationTaskHandlerCallback);
      expect(platform.startedNotification?.title, '00:05 — Étape step-1');
      expect(platform.startedNotification?.text, 'Suivant : Repos');
      expect(
        platform.startedNotification?.iconMetadataName,
        'session_notification_icon_play',
      );
      expect(platform.startedNotification?.buttonLabel, 'Pause');
      expect(platform.taskData, <Object>[data.toWire()]);
    },
  );

  test('met à jour le service déjà démarré sans le redémarrer', () async {
    final platform = _FakeServicePlatform(defaultRunning: true);
    final service = _service(platform, _FakePermissionPlatform());
    final data = _pin('step-1', isPlaying: false);

    await service.pin(
      data: data,
      onPausePressed: () {},
      onSoundThreshold: (_) {},
      onTimedStepEnded: (_, _) {},
    );

    expect(platform.startCalls, 0);
    expect(platform.taskData, <Object>[data.toWire()]);
  });

  test(
    'transmet Pause, seuil sonore et fin temporisée et rejette l’invalide',
    () async {
      final platform = _FakeServicePlatform(defaultRunning: true);
      final service = _service(platform, _FakePermissionPlatform());
      var pauseCalls = 0;
      final sounds = <String>[];
      final ends = <(String, NotificationMode)>[];
      await service.pin(
        data: _pin('step-1'),
        onPausePressed: () => pauseCalls++,
        onSoundThreshold: sounds.add,
        onTimedStepEnded: (token, mode) => ends.add((token, mode)),
      );

      platform.emit('pause');
      platform.emit(const SessionSoundThresholdReached('step-1').toWire());
      platform.emit(
        const SessionTimedStepEnded(
          'step-1',
          NotificationMode.vibration,
        ).toWire(),
      );
      platform.emit(<String, Object>{'event': 'inconnu'});

      expect(pauseCalls, 1);
      expect(sounds, <String>['step-1']);
      expect(ends, <(String, NotificationMode)>[
        ('step-1', NotificationMode.vibration),
      ]);
    },
  );

  test(
    'deux pin rapprochés appliquent uniquement la dernière révision',
    () async {
      final firstCheck = Completer<bool>();
      final secondCheck = Completer<bool>();
      final platform = _FakeServicePlatform(
        runningChecks: <Future<bool>>[firstCheck.future, secondCheck.future],
      );
      final service = _service(platform, _FakePermissionPlatform());

      final first = service.pin(
        data: _pin('step-1'),
        onPausePressed: () {},
        onSoundThreshold: (_) {},
        onTimedStepEnded: (_, _) {},
      );
      await _flush();
      final second = service.pin(
        data: _pin('step-2'),
        onPausePressed: () {},
        onSoundThreshold: (_) {},
        onTimedStepEnded: (_, _) {},
      );
      firstCheck.complete(false);
      await _flush();
      secondCheck.complete(true);
      await Future.wait(<Future<void>>[first, second]);

      expect(platform.startCalls, 0);
      expect(platform.taskData, <Object>[_pin('step-2').toWire()]);
    },
  );

  test('un stop invalide un pin en attente puis arrête le service', () async {
    final pinCheck = Completer<bool>();
    final stopCheck = Completer<bool>();
    final platform = _FakeServicePlatform(
      runningChecks: <Future<bool>>[pinCheck.future, stopCheck.future],
    );
    final service = _service(platform, _FakePermissionPlatform());

    final pin = service.pin(
      data: _pin('step-1'),
      onPausePressed: () {},
      onSoundThreshold: (_) {},
      onTimedStepEnded: (_, _) {},
    );
    await _flush();
    final stop = service.stop();
    pinCheck.complete(false);
    await _flush();
    stopCheck.complete(true);
    await Future.wait(<Future<void>>[pin, stop]);

    expect(platform.startCalls, 0);
    expect(platform.taskData, isEmpty);
    expect(platform.stopCalls, 1);
  });

  test('stop arrête uniquement un service en cours', () async {
    final stopped = _FakeServicePlatform(defaultRunning: true);
    final absent = _FakeServicePlatform();

    await _service(stopped, _FakePermissionPlatform()).stop();
    await _service(absent, _FakePermissionPlatform()).stop();

    expect(stopped.stopCalls, 1);
    expect(absent.stopCalls, 0);
  });

  test('absorbe les erreurs plugin sur init, pin, stop et dispose', () async {
    final platform = _FakeServicePlatform(throwOnCalls: true);
    final service = _service(platform, _FakePermissionPlatform());

    SessionNotificationService.initCommunicationPort(platform: platform);
    await service.pin(
      data: _pin('step-1'),
      onPausePressed: () {},
      onSoundThreshold: (_) {},
      onTimedStepEnded: (_, _) {},
    );
    await service.stop();
    service.dispose();
  });

  test('dispose retire le callback et nettoie les closures', () async {
    final platform = _FakeServicePlatform(defaultRunning: true);
    final service = _service(platform, _FakePermissionPlatform());
    var pauseCalls = 0;
    await service.pin(
      data: _pin('step-1'),
      onPausePressed: () => pauseCalls++,
      onSoundThreshold: (_) {},
      onTimedStepEnded: (_, _) {},
    );
    final removedCallback = platform.callback;

    service.dispose();
    removedCallback?.call('pause');

    expect(platform.removeCallbackCalls, 1);
    expect(platform.callback, isNull);
    expect(pauseCalls, 0);
  });
}

SessionNotificationService _service(
  _FakeServicePlatform platform,
  _FakePermissionPlatform permissions,
) => SessionNotificationService(
  platform: platform,
  permissionService: SessionNotificationPermissionService(
    platform: permissions,
  ),
);

SessionNotificationPinData _pin(String token, {bool isPlaying = true}) =>
    SessionNotificationPinData(
      stepLabel: 'Étape $token',
      nextStepLabel: 'Suivant : Repos',
      stepToken: token,
      notificationMode: NotificationMode.sound,
      isPlaying: isPlaying,
      isCountingDown: true,
      baseMilliseconds: 5000,
      pinEpochMillis: DateTime.utc(2026, 8, 11).millisecondsSinceEpoch,
      soundGoOffsetMilliseconds: 2400,
    );

Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _FakeServicePlatform implements SessionNotificationServicePlatform {
  _FakeServicePlatform({
    this.defaultRunning = false,
    List<Future<bool>>? runningChecks,
    this.throwOnCalls = false,
  }) : runningChecks = runningChecks ?? <Future<bool>>[];

  final bool defaultRunning;
  final List<Future<bool>> runningChecks;
  final bool throwOnCalls;
  int initCalls = 0;
  int addCallbackCalls = 0;
  int removeCallbackCalls = 0;
  int startCalls = 0;
  int stopCalls = 0;
  int? serviceId;
  Function? startCallback;
  SessionForegroundNotification? startedNotification;
  SessionTaskDataCallback? callback;
  final taskData = <Object>[];

  void _throwIfNeeded() {
    if (throwOnCalls) throw StateError('plugin');
  }

  @override
  void initCommunicationPort() {
    _throwIfNeeded();
    initCalls++;
  }

  @override
  void addTaskDataCallback(SessionTaskDataCallback callback) {
    _throwIfNeeded();
    addCallbackCalls++;
    this.callback = callback;
  }

  @override
  void removeTaskDataCallback(SessionTaskDataCallback callback) {
    _throwIfNeeded();
    removeCallbackCalls++;
    if (this.callback == callback) this.callback = null;
  }

  @override
  Future<bool> get isRunningService async {
    _throwIfNeeded();
    if (runningChecks.isNotEmpty) return await runningChecks.removeAt(0);
    return defaultRunning;
  }

  @override
  Future<void> startService({
    required int serviceId,
    required SessionForegroundNotification notification,
    required Function callback,
  }) async {
    _throwIfNeeded();
    startCalls++;
    this.serviceId = serviceId;
    startedNotification = notification;
    startCallback = callback;
  }

  @override
  void sendDataToTask(Object data) {
    _throwIfNeeded();
    taskData.add(data);
  }

  @override
  Future<void> stopService() async {
    _throwIfNeeded();
    stopCalls++;
  }

  void emit(Object data) => callback?.call(data);
}

class _FakePermissionPlatform implements SessionNotificationPermissionPlatform {
  int initializeCalls = 0;

  @override
  void initialize() => initializeCalls++;

  @override
  Future<SessionNotificationPermissionStatus>
  notificationPermissionStatus() async =>
      SessionNotificationPermissionStatus.granted;

  @override
  Future<SessionNotificationPermissionStatus>
  requestNotificationPermission() async =>
      SessionNotificationPermissionStatus.granted;

  @override
  Future<bool> openNotificationSettings() async => true;

  @override
  Future<BatteryOptimizationStatus> batteryOptimizationStatus() async =>
      BatteryOptimizationStatus.exempt;

  @override
  Future<void> requestBatteryOptimizationExemption() async {}
}
