import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'session_notification_platform.dart';
import 'session_notification_protocol.dart';
import 'step_end_trigger_scheduler.dart';

/// Point d'entrée Android exigé par flutter_foreground_task.
@pragma('vm:entry-point')
void sessionNotificationTaskHandlerCallback() {
  const platform = FlutterSessionNotificationPlatform();
  platform.setTaskHandler(SessionNotificationTaskHandler(platform: platform));
}

/// Adaptateur entre le Foreground Service Android et le domaine de
/// notification. Le calcul des seuils et l'anti-doublon sont délégués à
/// [StepEndTriggerScheduler].
class SessionNotificationTaskHandler extends TaskHandler {
  SessionNotificationTaskHandler({
    SessionNotificationTaskPlatform? platform,
    DateTime Function()? now,
    ScheduleTrigger? schedule,
  }) : _platform = platform ?? const FlutterSessionNotificationPlatform() {
    _scheduler = StepEndTriggerScheduler(
      onEvent: (event) => _sendDataToMain(event.toWire()),
      now: now,
      schedule: schedule,
    );
  }

  final SessionNotificationTaskPlatform _platform;
  SessionNotificationPinData? _state;
  late final StepEndTriggerScheduler _scheduler;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (!_scheduler.hasState) return;
    _scheduler.evaluate();
    unawaited(_updateNotification());
  }

  @override
  void onReceiveData(Object data) {
    final state = SessionNotificationPinData.fromWire(data);
    if (state == null) return;

    _state = state;
    _scheduler.update(state);
    unawaited(_updateNotification());
  }

  Future<void> _updateNotification() async {
    final state = _state;
    if (state == null) return;

    try {
      await _platform.updateNotification(
        SessionForegroundNotification.fromPin(
          state,
          _scheduler.currentMilliseconds,
        ),
      );
    } catch (_) {
      // Best effort : le service ne doit jamais interrompre la séance.
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    final action = SessionNotificationAction.fromWire(id);
    if (action != null) _sendDataToMain(action.name);
  }

  @override
  void onNotificationPressed() {
    try {
      _platform.launchApp();
    } catch (_) {}
  }

  void _sendDataToMain(Object data) {
    try {
      _platform.sendDataToMain(data);
    } catch (_) {}
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _scheduler.dispose();
  }
}
