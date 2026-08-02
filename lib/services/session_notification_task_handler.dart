import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../utils/formatters.dart';
import 'session_notification_protocol.dart';
import 'step_end_trigger_scheduler.dart';

/// Point d'entrée Android exigé par flutter_foreground_task.
@pragma('vm:entry-point')
void sessionNotificationTaskHandlerCallback() {
  FlutterForegroundTask.setTaskHandler(SessionNotificationTaskHandler());
}

/// Adaptateur entre le Foreground Service Android et le domaine de
/// notification. Le calcul des seuils et l'anti-doublon sont délégués à
/// [StepEndTriggerScheduler].
class SessionNotificationTaskHandler extends TaskHandler {
  SessionNotificationPinData? _state;
  late final StepEndTriggerScheduler _scheduler = StepEndTriggerScheduler(
    onEvent: (event) => FlutterForegroundTask.sendDataToMain(event.toWire()),
  );

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (!_scheduler.hasState) return;
    _scheduler.evaluate();
    _updateNotification();
  }

  @override
  void onReceiveData(Object data) {
    final state = SessionNotificationPinData.fromWire(data);
    if (state == null) return;

    _state = state;
    _scheduler.update(state);
    _updateNotification();
  }

  void _updateNotification() {
    final state = _state;
    if (state == null) return;

    final chronoText = formatDuration(
      Duration(milliseconds: _scheduler.currentMilliseconds),
    );

    unawaited(
      FlutterForegroundTask.updateService(
        notificationTitle: '$chronoText — ${state.stepLabel}',
        notificationText: state.nextStepLabel,
        notificationIcon: NotificationIcon(
          metaDataName: state.isPlaying
              ? 'session_notification_icon_play'
              : 'session_notification_icon_pause',
        ),
        notificationButtons: <NotificationButton>[
          NotificationButton(
            id: SessionNotificationAction.pause.name,
            text: state.isPlaying ? 'Pause' : 'Reprendre',
          ),
        ],
      ),
    );
  }

  @override
  void onNotificationButtonPressed(String id) {
    final action = SessionNotificationAction.fromWire(id);
    if (action != null) FlutterForegroundTask.sendDataToMain(action.name);
  }

  @override
  void onNotificationPressed() => FlutterForegroundTask.launchApp();

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _scheduler.dispose();
  }
}
