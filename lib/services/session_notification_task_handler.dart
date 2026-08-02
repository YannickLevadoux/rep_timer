import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../utils/formatters.dart';

/// Identifiant du bouton "Pause"/"Reprendre" de la notification étendue
/// (le libellé suit l'état, voir _updateNotification). Son appui doit
/// être traité par [SessionController] (isolate principal), seul à
/// connaître l'état réel de la séance.
const String sessionNotificationPauseButtonId = 'pause';

/// Point d'entrée du Foreground Service : fonction de callback exigée par
/// flutter_foreground_task, exécutée dans un isolate séparé de celui de
/// l'UI (voir la doc du plugin). Doit rester top-level avec l'annotation
/// `vm:entry-point` pour être atteignable depuis ce nouvel isolate.
@pragma('vm:entry-point')
void sessionNotificationTaskHandlerCallback() {
  FlutterForegroundTask.setTaskHandler(SessionNotificationTaskHandler());
}

/// Gestionnaire du Foreground Service.
///
/// Contrairement à une première version qui se contentait de relayer les
/// actions de la notification, celui-ci fait défiler lui-même le
/// chronomètre affiché, une fois par seconde (onRepeatEvent), à partir
/// du dernier "point de référence" reçu de [SessionController] (voir
/// onReceiveData) : valeur du chrono à un instant donné (epoch ms), plus
/// son sens (compte à rebours ou chronomètre). Ce isolate recalcule donc
/// la valeur courante localement à chaque tick, sans dépendre d'un
/// nouveau message à chaque seconde.
///
/// Ce choix corrige un vrai problème de fiabilité : en s'appuyant
/// uniquement sur l'isolate principal pour rafraîchir la notification
/// chaque seconde, l'affichage se figeait dès que l'utilisateur changeait
/// d'application sur certains appareils (restrictions d'arrière-plan
/// agressives de certains constructeurs, ex. MIUI, qui peuvent ralentir
/// l'isolate principal malgré le Foreground Service actif). Le calcul
/// vit ici, directement rattaché au composant Service, qui reste la
/// partie la plus protégée du processus.
///
/// [SessionController] reste néanmoins l'unique source de vérité pour la
/// logique de séance elle-même (détection de fin d'étape, son,
/// vibration...) : ce isolate ne fait qu'afficher un chronomètre dérivé
/// du dernier point de référence transmis, aucune logique dupliquée.
///
/// Notification à un seul bouton (Pause/Reprendre) : un bouton "Voir la
/// séance" a été essayé puis retiré — FlutterForegroundTask.launchApp()
/// appelé depuis un bouton d'action n'a silencieusement aucun effet sur
/// certains appareils (restriction Android de démarrage d'activité en
/// arrière-plan côté BroadcastReceiver d'action, contrairement au tap sur
/// le corps de la notification qui passe par un PendingIntent standard,
/// lui non restreint). Le tap sur le corps reste donc l'unique moyen de
/// revenir à l'application depuis la notification (voir
/// onNotificationPressed), pas besoin de bouton dédié pour ça.
class SessionNotificationTaskHandler extends TaskHandler {
  String _stepLabel = '';
  String _nextStepLabel = '';
  bool _isPlaying = true;
  bool _isCountingDown = true;
  int _baseSeconds = 0;
  int _pinEpochMillis = 0;

  // Tant qu'aucun point de référence n'a été reçu (juste après le
  // démarrage du service, avant que le premier message n'arrive), on ne
  // sait pas encore quoi afficher : onRepeatEvent ne fait rien plutôt que
  // d'écraser le contenu initial fourni par startService avec des valeurs
  // par défaut incorrectes.
  bool _hasState = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_hasState) _updateNotification();
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;

    _stepLabel = data['stepLabel'] as String? ?? _stepLabel;
    _nextStepLabel = data['nextStepLabel'] as String? ?? _nextStepLabel;
    _isPlaying = data['isPlaying'] as bool? ?? _isPlaying;
    _isCountingDown = data['isCountingDown'] as bool? ?? _isCountingDown;
    _baseSeconds = data['baseSeconds'] as int? ?? _baseSeconds;
    _pinEpochMillis =
        data['pinEpochMillis'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    _hasState = true;

    _updateNotification();
  }

  // Valeur courante du chrono (secondes), recalculée à partir du dernier
  // point de référence reçu. En pause, la valeur reste figée à
  // _baseSeconds (aucun temps ne s'écoule alors côté SessionController
  // non plus).
  int _currentSeconds() {
    if (!_isPlaying) return _baseSeconds;

    final elapsedSincePin =
        ((DateTime.now().millisecondsSinceEpoch - _pinEpochMillis) / 1000)
            .floor();
    final seconds = _isCountingDown
        ? _baseSeconds - elapsedSincePin
        : _baseSeconds + elapsedSincePin;

    return _isCountingDown && seconds < 0 ? 0 : seconds;
  }

  void _updateNotification() {
    final chronoText = formatDuration(Duration(seconds: _currentSeconds()));

    unawaited(
      FlutterForegroundTask.updateService(
        // Le chrono est placé en titre (plutôt qu'en texte) : c'est
        // l'élément le plus visible d'une notification Android, y
        // compris repliée.
        notificationTitle: "$chronoText — $_stepLabel",
        notificationText: _nextStepLabel,
        notificationIcon: NotificationIcon(
          metaDataName: _isPlaying
              ? 'session_notification_icon_play'
              : 'session_notification_icon_pause',
        ),
        notificationButtons: [
          NotificationButton(
            id: sessionNotificationPauseButtonId,
            text: _isPlaying ? "Pause" : "Reprendre",
          ),
        ],
      ),
    );
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == sessionNotificationPauseButtonId) {
      FlutterForegroundTask.sendDataToMain(id);
    }
  }

  @override
  void onNotificationPressed() {
    // Seul moyen de revenir à l'application depuis la notification (voir
    // le commentaire de classe : contrairement à un bouton d'action, ce
    // tap passe par un PendingIntent standard, non soumis aux
    // restrictions Android de démarrage d'activité en arrière-plan.
    FlutterForegroundTask.launchApp();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
