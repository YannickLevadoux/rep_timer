import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../models/notification_mode.dart';
import '../utils/formatters.dart';
import 'session_notification_permission_service.dart';
import 'session_notification_protocol.dart';
import 'session_notification_task_handler.dart';

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
  SessionNotificationService({
    SessionNotificationPermissionService? permissionService,
  }) : _permissionService =
           permissionService ?? SessionNotificationPermissionService();

  final SessionNotificationPermissionService _permissionService;
  bool _dataCallbackRegistered = false;
  int _pinRevision = 0;
  Future<void> _pinQueue = Future<void>.value();

  void Function()? _onPausePressed;
  void Function(String stepToken)? _onSoundThreshold;
  void Function(String stepToken, NotificationMode mode)? _onTimedStepEnded;

  void _handleTaskData(dynamic data) {
    if (SessionNotificationAction.fromWire(data) ==
        SessionNotificationAction.pause) {
      _onPausePressed?.call();
      return;
    }

    final event = SessionNotificationEvent.fromWire(data);
    if (event is SessionSoundThresholdReached) {
      _onSoundThreshold?.call(event.stepToken);
    } else if (event is SessionTimedStepEnded) {
      _onTimedStepEnded?.call(event.stepToken, event.notificationMode);
    }
  }

  /// À appeler une seule fois avant `runApp` (voir `main.dart`) : requis
  /// par le plugin pour que l'isolate principal puisse recevoir les
  /// messages envoyés par le TaskHandler, y compris avant qu'une séance
  /// n'ait démarré.
  static void initCommunicationPort() {
    FlutterForegroundTask.initCommunicationPort();
  }

  /// Affiche ou met à jour la notification persistante à partir d'un
  /// "point de référence" typé ([data]). Le TaskHandler du Foreground Service
  /// se charge
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
    required SessionNotificationPinData data,
    required void Function() onPausePressed,
    required void Function(String stepToken) onSoundThreshold,
    required void Function(String stepToken, NotificationMode mode)
    onTimedStepEnded,
  }) {
    _permissionService.ensureInitialized();
    _onPausePressed = onPausePressed;
    _onSoundThreshold = onSoundThreshold;
    _onTimedStepEnded = onTimedStepEnded;

    if (!_dataCallbackRegistered) {
      _dataCallbackRegistered = true;
      FlutterForegroundTask.addTaskDataCallback(_handleTaskData);
    }

    final revision = ++_pinRevision;
    final operation = _pinQueue.then(
      (_) => _applyPin(revision: revision, data: data),
    );
    _pinQueue = operation.then<void>((_) {}, onError: (_) {});
    return operation;
  }

  Future<void> _applyPin({
    required int revision,
    required SessionNotificationPinData data,
  }) async {
    if (revision != _pinRevision) return;

    try {
      if (await FlutterForegroundTask.isRunningService) {
        if (revision != _pinRevision) return;
        FlutterForegroundTask.sendDataToTask(data.toWire());
        return;
      }
      if (revision != _pinRevision) return;

      // Premier affichage : le TaskHandler n'est pas encore démarré, on
      // fournit donc un contenu initial correct directement à
      // startService (le TaskHandler prendra ensuite le relai dès qu'il
      // aura reçu ce même point de référence, envoyé juste après).
      final chronoText = formatDuration(
        Duration(milliseconds: data.baseMilliseconds),
      );

      await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        notificationTitle: '$chronoText — ${data.stepLabel}',
        notificationText: data.nextStepLabel,
        notificationIcon: NotificationIcon(
          metaDataName: data.isPlaying
              ? 'session_notification_icon_play'
              : 'session_notification_icon_pause',
        ),
        notificationButtons: <NotificationButton>[
          NotificationButton(
            id: SessionNotificationAction.pause.name,
            text: data.isPlaying ? 'Pause' : 'Reprendre',
          ),
        ],
        callback: sessionNotificationTaskHandlerCallback,
      );

      if (revision == _pinRevision) {
        FlutterForegroundTask.sendDataToTask(data.toWire());
      }
    } catch (_) {
      // Cf. commentaire de classe : jamais bloquant pour la séance.
    }
  }

  /// Arrête le Foreground Service et retire la notification. Sans effet
  /// s'il n'était pas démarré (ex : séance entièrement en mode
  /// Répétitions, jamais affichée).
  Future<void> stop() {
    final revision = ++_pinRevision;
    final operation = _pinQueue.then((_) => _applyStop(revision));
    _pinQueue = operation.then<void>((_) {}, onError: (_) {});
    return operation;
  }

  Future<void> _applyStop(int revision) async {
    if (revision != _pinRevision) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        if (revision != _pinRevision) return;
        await FlutterForegroundTask.stopService();
      }
    } catch (_) {
      // Best effort, comme pin() ci-dessus.
    }
  }

  void dispose() {
    if (_dataCallbackRegistered) {
      FlutterForegroundTask.removeTaskDataCallback(_handleTaskData);
      _dataCallbackRegistered = false;
    }
    _onPausePressed = null;
    _onSoundThreshold = null;
    _onTimedStepEnded = null;
  }
}
