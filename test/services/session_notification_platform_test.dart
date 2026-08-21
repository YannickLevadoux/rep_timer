import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/services/session_notification_permission_service.dart';
import 'package:rep_timer/services/session_notification_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodsChannel = MethodChannel('flutter_foreground_task/methods');
  const backgroundChannel = MethodChannel('flutter_foreground_task/background');
  const permissionsChannel = MethodChannel(
    'com.yannicklevadoux.reptimer/permissions',
  );

  setUp(() {
    FlutterForegroundTask.resetStatic();
  });

  tearDown(() {
    FlutterForegroundTask.resetStatic();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(methodsChannel, null);
    messenger.setMockMethodCallHandler(backgroundChannel, null);
    messenger.setMockMethodCallHandler(permissionsChannel, null);
  });

  test('l’adaptateur par défaut convertit permissions et batterie', () async {
    var notificationIndex = NotificationPermission.granted.index;
    final calls = <String>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(methodsChannel, (call) async {
      calls.add(call.method);
      return switch (call.method) {
        'checkNotificationPermission' => notificationIndex,
        'requestNotificationPermission' => NotificationPermission.granted.index,
        _ => true,
      };
    });
    messenger.setMockMethodCallHandler(
      permissionsChannel,
      (call) async => call.method == 'openNotificationSettings',
    );
    final service = SessionNotificationPermissionService();

    expect(service.ensureInitialized(), isTrue);
    for (final entry
        in <NotificationPermission, SessionNotificationPermissionStatus>{
          NotificationPermission.granted:
              SessionNotificationPermissionStatus.granted,
          NotificationPermission.denied:
              SessionNotificationPermissionStatus.denied,
          NotificationPermission.permanently_denied:
              SessionNotificationPermissionStatus.permanentlyDenied,
        }.entries) {
      notificationIndex = entry.key.index;
      expect(await service.notificationPermissionStatus(), entry.value);
    }
    notificationIndex = NotificationPermission.denied.index;
    expect(
      await service.requestNotificationPermission(),
      SessionNotificationPermissionStatus.granted,
    );
    expect(await service.openNotificationSettings(), isTrue);
    expect(
      await service.batteryOptimizationStatus(),
      BatteryOptimizationStatus.exempt,
    );
    expect(
      await service.requestBatteryOptimizationExemption(),
      BatteryOptimizationStatus.exempt,
    );
    expect(calls, contains('requestNotificationPermission'));
  });

  test('relaie les opérations du service de notification', () async {
    var running = false;
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(methodsChannel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'isRunningService':
          return running;
        case 'startService':
          running = true;
        case 'stopService':
          running = false;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(backgroundChannel, (_) async => null);
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'test',
        channelName: 'Test',
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
      ),
    );
    FlutterForegroundTask.skipServiceResponseCheck = true;
    const platform = FlutterSessionNotificationPlatform();
    const notification = SessionForegroundNotification(
      title: '00:10 — Pompes',
      text: 'Pause',
      iconMetadataName: 'session_notification_icon_play',
      buttonId: 'pause',
      buttonLabel: 'Pause',
    );
    final received = <Object>[];
    void callback(Object data) => received.add(data);

    platform.setTaskHandler(_TaskHandler());
    platform.initCommunicationPort();
    platform.addTaskDataCallback(callback);
    platform.addTaskDataCallback(callback);
    platform.sendDataToMain('depuis la tâche');
    await Future<void>.delayed(Duration.zero);
    expect(received, ['depuis la tâche']);
    platform.removeTaskDataCallback(callback);

    expect(await platform.isRunningService, isFalse);
    await platform.startService(
      serviceId: 203,
      notification: notification,
      callback: _foregroundCallback,
    );
    expect(await platform.isRunningService, isTrue);
    await platform.updateNotification(notification);
    platform.sendDataToTask('vers la tâche');
    platform.launchApp();
    await platform.stopService();

    expect(
      calls.map((call) => call.method),
      containsAll(<String>[
        'startService',
        'updateService',
        'sendData',
        'stopService',
      ]),
    );
  });
}

void _foregroundCallback() {}

class _TaskHandler extends TaskHandler {
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}
}
