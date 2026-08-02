import 'package:flutter_foreground_task/flutter_foreground_task.dart';

const String _channelId = 'session_progress';
const String _channelName = 'Progression de la séance';

/// Accès Android minimal requis par la politique de permissions. Cette
/// interface garde la décision de demander une permission testable sans canal
/// de plateforme.
abstract interface class SessionNotificationPermissionPlatform {
  void initialize();
  Future<bool> hasNotificationPermission();
  Future<void> requestNotificationPermission();
  Future<bool> isIgnoringBatteryOptimizations();
  Future<void> requestIgnoreBatteryOptimization();
}

/// Gère l'initialisation du canal Android et les permissions nécessaires au
/// Foreground Service de séance.
class SessionNotificationPermissionService {
  factory SessionNotificationPermissionService({
    SessionNotificationPermissionPlatform? platform,
  }) => SessionNotificationPermissionService._(
    platform ?? _ForegroundTaskPermissionPlatform(),
  );

  SessionNotificationPermissionService._(this._platform);

  final SessionNotificationPermissionPlatform _platform;
  static bool _autoPermissionsRequested = false;

  void ensureInitialized() => _platform.initialize();

  /// Best effort : un refus ne doit jamais interrompre la séance.
  Future<void> requestPermissions() async {
    ensureInitialized();

    try {
      if (!await _platform.hasNotificationPermission()) {
        await _platform.requestNotificationPermission();
      }
    } catch (_) {}

    try {
      if (!await _platform.isIgnoringBatteryOptimizations()) {
        await _platform.requestIgnoreBatteryOptimization();
      }
    } catch (_) {}
  }

  /// Déclenche la demande implicite une seule fois pendant la vie du
  /// processus. L'écran Paramètres peut toujours relancer explicitement
  /// [requestPermissions].
  Future<void> ensureAutoPermissionsRequested() async {
    if (_autoPermissionsRequested) return;
    _autoPermissionsRequested = true;
    await requestPermissions();
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
  Future<bool> hasNotificationPermission() async =>
      await FlutterForegroundTask.checkNotificationPermission() ==
      NotificationPermission.granted;

  @override
  Future<void> requestNotificationPermission() async {
    await FlutterForegroundTask.requestNotificationPermission();
  }

  @override
  Future<bool> isIgnoringBatteryOptimizations() =>
      FlutterForegroundTask.isIgnoringBatteryOptimizations;

  @override
  Future<void> requestIgnoreBatteryOptimization() async {
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }
}
