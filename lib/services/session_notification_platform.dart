import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../utils/formatters.dart';
import 'session_notification_protocol.dart';

typedef SessionTaskDataCallback = void Function(Object data);

/// Contenu commun au premier affichage et aux mises à jour de la notification.
class SessionForegroundNotification {
  const SessionForegroundNotification({
    required this.title,
    required this.text,
    required this.iconMetadataName,
    required this.buttonId,
    required this.buttonLabel,
  });

  factory SessionForegroundNotification.fromPin(
    SessionNotificationPinData data,
    int currentMilliseconds,
  ) {
    final chronoText = formatDuration(
      Duration(milliseconds: currentMilliseconds),
    );
    return SessionForegroundNotification(
      title: '$chronoText — ${data.stepLabel}',
      text: data.nextStepLabel,
      iconMetadataName: data.isPlaying
          ? 'session_notification_icon_play'
          : 'session_notification_icon_pause',
      buttonId: SessionNotificationAction.pause.name,
      buttonLabel: data.isPlaying ? 'Pause' : 'Reprendre',
    );
  }

  final String title;
  final String text;
  final String iconMetadataName;
  final String buttonId;
  final String buttonLabel;
}

/// Frontière utilisée dans l'isolate du Foreground Service Android.
abstract interface class SessionNotificationTaskPlatform {
  void setTaskHandler(TaskHandler handler);
  void sendDataToMain(Object data);
  Future<void> updateNotification(SessionForegroundNotification notification);
  void launchApp();
}

/// Frontière utilisée dans l'isolate principal de l'application.
abstract interface class SessionNotificationServicePlatform {
  void initCommunicationPort();
  void addTaskDataCallback(SessionTaskDataCallback callback);
  void removeTaskDataCallback(SessionTaskDataCallback callback);
  Future<bool> get isRunningService;
  Future<void> startService({
    required int serviceId,
    required SessionForegroundNotification notification,
    required Function callback,
  });
  void sendDataToTask(Object data);
  Future<void> stopService();
}

/// Implémentation de production conservant les appels plugin existants.
class FlutterSessionNotificationPlatform
    implements
        SessionNotificationTaskPlatform,
        SessionNotificationServicePlatform {
  const FlutterSessionNotificationPlatform();

  @override
  void setTaskHandler(TaskHandler handler) {
    FlutterForegroundTask.setTaskHandler(handler);
  }

  @override
  void sendDataToMain(Object data) {
    FlutterForegroundTask.sendDataToMain(data);
  }

  @override
  Future<void> updateNotification(
    SessionForegroundNotification notification,
  ) async {
    await FlutterForegroundTask.updateService(
      notificationTitle: notification.title,
      notificationText: notification.text,
      notificationIcon: NotificationIcon(
        metaDataName: notification.iconMetadataName,
      ),
      notificationButtons: <NotificationButton>[
        NotificationButton(
          id: notification.buttonId,
          text: notification.buttonLabel,
        ),
      ],
    );
  }

  @override
  void launchApp() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void initCommunicationPort() {
    FlutterForegroundTask.initCommunicationPort();
  }

  @override
  void addTaskDataCallback(SessionTaskDataCallback callback) {
    FlutterForegroundTask.addTaskDataCallback(callback);
  }

  @override
  void removeTaskDataCallback(SessionTaskDataCallback callback) {
    FlutterForegroundTask.removeTaskDataCallback(callback);
  }

  @override
  Future<bool> get isRunningService => FlutterForegroundTask.isRunningService;

  @override
  Future<void> startService({
    required int serviceId,
    required SessionForegroundNotification notification,
    required Function callback,
  }) async {
    await FlutterForegroundTask.startService(
      serviceId: serviceId,
      notificationTitle: notification.title,
      notificationText: notification.text,
      notificationIcon: NotificationIcon(
        metaDataName: notification.iconMetadataName,
      ),
      notificationButtons: <NotificationButton>[
        NotificationButton(
          id: notification.buttonId,
          text: notification.buttonLabel,
        ),
      ],
      callback: callback,
    );
  }

  @override
  void sendDataToTask(Object data) {
    FlutterForegroundTask.sendDataToTask(data);
  }

  @override
  Future<void> stopService() async {
    await FlutterForegroundTask.stopService();
  }
}
