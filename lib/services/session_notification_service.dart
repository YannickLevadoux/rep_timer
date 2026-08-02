import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../utils/formatters.dart';
import 'session_notification_task_handler.dart';

/// Identifiant fixe du canal de notification (voir Paramètres système >
/// Notifications > RepTimer, un seul canal pour cette fonctionnalité).
const String _channelId = 'session_progress';
const String _channelName = 'Progression de la séance';
const int _serviceId = 4200;

/// Notification Android persistante affichée pendant qu'un chronomètre ou
/// un compte à rebours est actif dans une séance en cours (pause,
/// exercice Temps, exercice Durée libre) — jamais pour un exercice
/// Répétitions (voir SessionController._stepNeedsNotification).
///
/// Repose sur un vrai Foreground Service (flutter_foreground_task) plutôt
/// que sur une simple notification "ongoing" : sans un Foreground
/// Service, Android peut geler l'intégralité du processus dès que
/// l'application passe en arrière-plan ("cached apps freezer", depuis
/// Android 12), ce qui empêcherait aussi bien la mise à jour de cette
/// notification que le son/la vibration de fin d'exercice (voir
/// StepEndNotificationService) de se déclencher pendant que l'utilisateur
/// utilise une autre application.
///
/// Le défilement du chronomètre lui-même n'est PAS piloté depuis cette
/// classe (isolate principal) : on transmet seulement un "point de
/// référence" horodaté (voir [pin]) au TaskHandler du Foreground Service
/// (voir session_notification_task_handler.dart), qui recalcule et
/// affiche la valeur courante chaque seconde de son côté. C'est ce
/// isolate, directement rattaché au Service, qui reste le plus fiable
/// pour continuer à s'exécuter pendant que l'utilisateur utilise une
/// autre application.
///
/// Le caractère non-supprimable par balayage de la notification est une
/// propriété intrinsèque des notifications de Foreground Service sur
/// Android (contrairement à une notification "ongoing" classique) : rien
/// à configurer explicitement ici pour ça.
class SessionNotificationService {
  static bool _pluginInitialized = false;
  static bool _autoPermissionsRequested = false;
  bool _dataCallbackRegistered = false;

  void Function()? _onPausePressed;

  void _ensurePluginInitialized() {
    if (_pluginInitialized) return;
    _pluginInitialized = true;

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
      // eventAction périodique requis par l'API du plugin : c'est lui qui
      // déclenche onRepeatEvent chaque seconde côté TaskHandler, qui
      // recalcule alors lui-même la valeur du chrono à afficher (voir
      // session_notification_task_handler.dart).
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  void _handleTaskData(dynamic data) {
    if (data == sessionNotificationPauseButtonId) {
      _onPausePressed?.call();
    }
  }

  /// À appeler une seule fois avant `runApp` (voir `main.dart`) : requis
  /// par le plugin pour que l'isolate principal puisse recevoir les
  /// messages envoyés par le TaskHandler, y compris avant qu'une séance
  /// n'ait démarré.
  static void initCommunicationPort() {
    FlutterForegroundTask.initCommunicationPort();
  }

  /// Demande les permissions dont dépend la fiabilité de la notification
  /// persistante : notification (Android 13+, sans laquelle le Foreground
  /// Service démarre bien mais n'affiche jamais rien) et exemption
  /// d'optimisation de batterie (nécessaire sur certains constructeurs,
  /// ex. MIUI, dont la gestion de batterie peut ralentir l'app en
  /// arrière-plan malgré le Foreground Service actif).
  ///
  /// Exposée publiquement (contrairement à une simple demande automatique
  /// à usage unique) pour pouvoir être redéclenchée explicitement depuis
  /// l'écran Paramètres ("Activer les notifications de séance"), par
  /// exemple si l'utilisateur avait refusé une permission par erreur.
  /// Best effort : une permission refusée dégrade la fiabilité
  /// correspondante mais ne doit jamais empêcher le déroulement de la
  /// séance.
  Future<void> requestPermissions() async {
    _ensurePluginInitialized();

    try {
      final notificationPermission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
    } catch (_) {}

    try {
      final ignoringBatteryOptimizations =
          await FlutterForegroundTask.isIgnoringBatteryOptimizations;
      if (!ignoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    } catch (_) {}
  }

  // Déclenche requestPermissions() automatiquement, mais une seule fois
  // par installation (voir pin()) : les demandes suivantes ne peuvent
  // venir que d'un geste explicite de l'utilisateur, voir
  // requestPermissions() ci-dessus.
  Future<void> _ensureAutoPermissionsRequested() async {
    if (_autoPermissionsRequested) return;
    _autoPermissionsRequested = true;
    await requestPermissions();
  }

  /// Affiche ou met à jour la notification persistante à partir d'un
  /// "point de référence" : la valeur du chrono ([baseSeconds]) telle
  /// qu'elle est exacte au moment de l'appel, plus son sens
  /// ([isCountingDown]). Le TaskHandler du Foreground Service se charge
  /// ensuite de faire défiler l'affichage chaque seconde à partir de ce
  /// point — voir session_notification_task_handler.dart.
  ///
  /// [onPausePressed] est invoqué (sur l'isolate principal) lorsque
  /// l'utilisateur appuie sur le bouton "Pause"/"Reprendre" de la
  /// notification étendue ; ré-affecté à chaque appel, ce qui permet de
  /// toujours pointer vers la séance actuellement en cours sans
  /// ré-enregistrer un écouteur supplémentaire.
  ///
  /// Best effort, comme les autres services de notification de
  /// l'application (voir StepEndNotificationService) : une notification
  /// manquante ne doit jamais empêcher le déroulement de la séance.
  Future<void> pin({
    required String stepLabel,
    required String nextStepLabel,
    required bool isPlaying,
    required bool isCountingDown,
    required int baseSeconds,
    required void Function() onPausePressed,
  }) async {
    _ensurePluginInitialized();
    _onPausePressed = onPausePressed;

    if (!_dataCallbackRegistered) {
      _dataCallbackRegistered = true;
      FlutterForegroundTask.addTaskDataCallback(_handleTaskData);
    }

    await _ensureAutoPermissionsRequested();

    final pinData = <String, dynamic>{
      'stepLabel': stepLabel,
      'nextStepLabel': nextStepLabel,
      'isPlaying': isPlaying,
      'isCountingDown': isCountingDown,
      'baseSeconds': baseSeconds,
      'pinEpochMillis': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      if (await FlutterForegroundTask.isRunningService) {
        FlutterForegroundTask.sendDataToTask(pinData);
        return;
      }

      // Premier affichage : le TaskHandler n'est pas encore démarré, on
      // fournit donc un contenu initial correct directement à
      // startService (le TaskHandler prendra ensuite le relai dès qu'il
      // aura reçu ce même point de référence, envoyé juste après).
      final chronoText = formatDuration(Duration(seconds: baseSeconds));

      await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        notificationTitle: "$chronoText — $stepLabel",
        notificationText: nextStepLabel,
        notificationIcon: NotificationIcon(
          metaDataName: isPlaying
              ? 'session_notification_icon_play'
              : 'session_notification_icon_pause',
        ),
        notificationButtons: [
          NotificationButton(
            id: sessionNotificationPauseButtonId,
            text: isPlaying ? "Pause" : "Reprendre",
          ),
        ],
        callback: sessionNotificationTaskHandlerCallback,
      );

      FlutterForegroundTask.sendDataToTask(pinData);
    } catch (_) {
      // Cf. commentaire de classe : jamais bloquant pour la séance.
    }
  }

  /// Arrête le Foreground Service et retire la notification. Sans effet
  /// s'il n'était pas démarré (ex : séance entièrement en mode
  /// Répétitions, jamais affichée).
  Future<void> stop() async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (_) {
      // Best effort, comme pin() ci-dessus.
    }
  }
}
