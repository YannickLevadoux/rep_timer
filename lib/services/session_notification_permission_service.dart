import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

const String _channelId = 'session_progress';
const String _channelName = 'Progression de la séance';
const MethodChannel _permissionsChannel = MethodChannel(
  'com.yannicklevadoux.reptimer/permissions',
);

enum SessionNotificationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  unavailable,
}

enum BatteryOptimizationStatus { optimized, exempt, unavailable }

/// Toutes les interactions système sont regroupées derrière ce contrat afin
/// que les parcours puissent être testés sans ouvrir d'interface Android.
abstract interface class SessionNotificationPermissionPlatform {
  void initialize();
  Future<SessionNotificationPermissionStatus> notificationPermissionStatus();
  Future<SessionNotificationPermissionStatus> requestNotificationPermission();
  Future<bool> openNotificationSettings();
  Future<BatteryOptimizationStatus> batteryOptimizationStatus();
  Future<void> requestBatteryOptimizationExemption();
}

/// Initialise le canal et expose séparément chaque lecture ou action liée aux
/// notifications de séance. Une erreur de plateforme est toujours convertie
/// en état exploitable : elle ne remonte jamais jusqu'au parcours de séance.
class SessionNotificationPermissionService {
  factory SessionNotificationPermissionService({
    SessionNotificationPermissionPlatform? platform,
  }) => SessionNotificationPermissionService._(
    platform ?? _ForegroundTaskPermissionPlatform(),
  );

  SessionNotificationPermissionService._(this._platform);

  final SessionNotificationPermissionPlatform _platform;

  bool ensureInitialized() {
    try {
      _platform.initialize();
      return true;
    } on Object {
      return false;
    }
  }

  Future<SessionNotificationPermissionStatus>
  notificationPermissionStatus() async {
    ensureInitialized();
    try {
      return await _platform.notificationPermissionStatus();
    } on Object {
      return SessionNotificationPermissionStatus.unavailable;
    }
  }

  Future<SessionNotificationPermissionStatus>
  requestNotificationPermission() async {
    final current = await notificationPermissionStatus();
    if (current == SessionNotificationPermissionStatus.granted ||
        current == SessionNotificationPermissionStatus.permanentlyDenied ||
        current == SessionNotificationPermissionStatus.unavailable) {
      return current;
    }

    try {
      return await _platform.requestNotificationPermission();
    } on Object {
      return SessionNotificationPermissionStatus.unavailable;
    }
  }

  Future<bool> openNotificationSettings() async {
    ensureInitialized();
    try {
      return await _platform.openNotificationSettings();
    } on Object {
      return false;
    }
  }

  Future<BatteryOptimizationStatus> batteryOptimizationStatus() async {
    ensureInitialized();
    try {
      return await _platform.batteryOptimizationStatus();
    } on Object {
      return BatteryOptimizationStatus.unavailable;
    }
  }

  Future<BatteryOptimizationStatus>
  requestBatteryOptimizationExemption() async {
    final current = await batteryOptimizationStatus();
    if (current != BatteryOptimizationStatus.optimized) return current;

    try {
      await _platform.requestBatteryOptimizationExemption();
      return await batteryOptimizationStatus();
    } on Object {
      return BatteryOptimizationStatus.unavailable;
    }
  }
}

class _ForegroundTaskPermissionPlatform
    implements SessionNotificationPermissionPlatform {
  static bool _initialized = false;

  @override
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: _channelName,
        channelDescription:
            "Notification de suivi d'une séance en cours (chronomètre ou "
            "compte à rebours), pour continuer à suivre sa progression "
            "sans revenir dans l'application.",
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.DEFAULT,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  @override
  Future<SessionNotificationPermissionStatus>
  notificationPermissionStatus() async => _mapNotificationStatus(
    await FlutterForegroundTask.checkNotificationPermission(),
  );

  @override
  Future<SessionNotificationPermissionStatus>
  requestNotificationPermission() async => _mapNotificationStatus(
    await FlutterForegroundTask.requestNotificationPermission(),
  );

  SessionNotificationPermissionStatus _mapNotificationStatus(
    NotificationPermission status,
  ) => switch (status) {
    NotificationPermission.granted =>
      SessionNotificationPermissionStatus.granted,
    NotificationPermission.denied => SessionNotificationPermissionStatus.denied,
    NotificationPermission.permanently_denied =>
      SessionNotificationPermissionStatus.permanentlyDenied,
  };

  @override
  Future<bool> openNotificationSettings() async =>
      await _permissionsChannel.invokeMethod<bool>(
        'openNotificationSettings',
      ) ??
      false;

  @override
  Future<BatteryOptimizationStatus> batteryOptimizationStatus() async =>
      await FlutterForegroundTask.isIgnoringBatteryOptimizations
      ? BatteryOptimizationStatus.exempt
      : BatteryOptimizationStatus.optimized;

  @override
  Future<void> requestBatteryOptimizationExemption() async {
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }
}
