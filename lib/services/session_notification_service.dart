import 'package:flutter_foreground_task/flutter_foreground_task.dart';

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
/// utilise une autre application. Un Foreground Service actif exempte
/// tout le processus de ce gel : les Timer existants de
/// SessionController (isolate principal) continuent donc de fonctionner
/// normalement, sans qu'aucune logique métier n'ait besoin d'être
/// dupliquée dans le isolate séparé du service (voir
/// session_notification_task_handler.dart, volontairement minimal).
///
/// Le caractère non-supprimable par balayage de la notification est une
/// propriété intrinsèque des notifications de Foreground Service sur
/// Android (contrairement à une notification "ongoing" classique) : rien
/// à configurer explicitement ici pour ça.
class SessionNotificationService {
  static bool _pluginInitialized = false;
  static bool _permissionRequested = false;
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
      // eventAction périodique requis par l'API du plugin, mais sans
      // effet ici : onRepeatEvent ne fait rien (voir TaskHandler), tout
      // le pilotage vient de SessionController via show()/stop().
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

  /// Affiche ou met à jour la notification persistante. Démarre le
  /// Foreground Service au premier appel, puis se contente de mettre à
  /// jour son contenu (icône, texte, boutons) aux appels suivants —
  /// sans jamais relancer le service inutilement.
  ///
  /// [onPausePressed] est invoqué (sur l'isolate principal) lorsque
  /// l'utilisateur appuie sur le bouton "Pause" de la notification
  /// étendue ; ré-affecté à chaque appel, ce qui permet de toujours
  /// pointer vers la séance actuellement en cours sans ré-enregistrer un
  /// écouteur supplémentaire.
  ///
  /// Best effort, comme les autres services de notification de
  /// l'application (voir StepEndNotificationService) : une notification
  /// manquante (permission refusée, service indisponible...) ne doit
  /// jamais empêcher le déroulement de la séance.
  Future<void> show({
    required String stepLabel,
    required String chronoText,
    required String nextStepLabel,
    required bool isPlaying,
    required void Function() onPausePressed,
  }) async {
    _ensurePluginInitialized();
    _onPausePressed = onPausePressed;

    if (!_dataCallbackRegistered) {
      _dataCallbackRegistered = true;
      FlutterForegroundTask.addTaskDataCallback(_handleTaskData);
    }

    final title = "Rep Timer";
    // Ligne 1 (visible même repliée) : nom de l'étape + chronomètre sur
    // une seule ligne — Android n'affiche de façon fiable qu'une seule
    // ligne de contenu tant que la notification n'est pas développée, un
    // vrai rendu sur deux lignes distinctes nécessiterait des
    // RemoteViews personnalisées, hors de portée de l'API simple de ce
    // plugin. Ligne 2 (visible une fois développée, avec les actions) :
    // prochain élément de la séance.
    final text = "$stepLabel — $chronoText\n$nextStepLabel";

    final icon = NotificationIcon(
      metaDataName: isPlaying
          ? 'session_notification_icon_play'
          : 'session_notification_icon_pause',
    );

    final buttons = [
      const NotificationButton(
        id: sessionNotificationPauseButtonId,
        text: "Pause",
      ),
      const NotificationButton(
        id: sessionNotificationOpenButtonId,
        text: "Voir la séance",
      ),
    ];

    try {
      if (!_permissionRequested) {
        _permissionRequested = true;
        final permission =
            await FlutterForegroundTask.checkNotificationPermission();
        if (permission != NotificationPermission.granted) {
          // Android 13+ : sans cette demande explicite, le Foreground
          // Service démarre bien en interne mais Android n'affiche
          // jamais la notification associée, sans la moindre erreur ni
          // log — un comportement très facile à confondre avec un bug
          // du plugin. Ne fait rien de plus si refusée : voir le
          // commentaire de classe, jamais bloquant pour la séance.
          await FlutterForegroundTask.requestNotificationPermission();
        }
      }

      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
          notificationIcon: icon,
          notificationButtons: buttons,
        );
      } else {
        await FlutterForegroundTask.startService(
          serviceId: _serviceId,
          notificationTitle: title,
          notificationText: text,
          notificationIcon: icon,
          notificationButtons: buttons,
          callback: sessionNotificationTaskHandlerCallback,
        );
      }
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
      // Best effort, comme show() ci-dessus.
    }
  }
}