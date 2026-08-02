import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../utils/formatters.dart';

/// Identifiant du bouton "Pause"/"Reprendre" de la notification étendue
/// (le libellé suit l'état, voir _updateNotification). Son appui doit
/// être traité par [SessionController] (isolate principal), seul à
/// connaître l'état réel de la séance.
const String sessionNotificationPauseButtonId = 'pause';
const String sessionNotificationSoundThresholdEvent = 'soundThreshold';
const String sessionNotificationTimedStepEndedEvent = 'timedStepEnded';

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
/// [SessionController] reste l'unique source de vérité pour la progression
/// de la séance. Ce TaskHandler prend seulement en charge les seuils de fin
/// de l'étape chronométrée qui lui est confiée, puis les signale à l'isolate
/// principal pour jouer le son/vibrer et synchroniser le contrôleur.
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
  String _stepToken = '';
  String _notificationMode = 'none';
  bool _isPlaying = true;
  bool _isCountingDown = true;
  int _baseMilliseconds = 0;
  int _pinEpochMillis = 0;
  int _soundGoOffsetMilliseconds = 0;

  Timer? _soundTimer;
  Timer? _stepEndTimer;

  // Le TaskHandler peut recevoir plusieurs resynchronisations pour une
  // même occurrence d'étape (pause, reprise, retour au premier plan...).
  // Ces ensembles garantissent que chaque seuil n'est signalé qu'une fois.
  final Set<String> _soundThresholdsSent = <String>{};
  final Set<String> _soundThresholdsArmed = <String>{};
  final Set<String> _stepEndsSent = <String>{};

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
    if (!_hasState) return;
    _evaluateStepEndNotifications();
    _updateNotification();
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;

    _stepLabel = data['stepLabel'] as String? ?? _stepLabel;
    _nextStepLabel = data['nextStepLabel'] as String? ?? _nextStepLabel;
    _stepToken = data['stepToken'] as String? ?? _stepToken;
    _notificationMode =
        data['notificationMode'] as String? ?? _notificationMode;
    _isPlaying = data['isPlaying'] as bool? ?? _isPlaying;
    _isCountingDown = data['isCountingDown'] as bool? ?? _isCountingDown;
    _baseMilliseconds = data['baseMilliseconds'] as int? ?? _baseMilliseconds;
    _pinEpochMillis =
        data['pinEpochMillis'] as int? ?? DateTime.now().millisecondsSinceEpoch;
    _soundGoOffsetMilliseconds =
        data['soundGoOffsetMilliseconds'] as int? ?? _soundGoOffsetMilliseconds;
    _hasState = true;

    _scheduleStepEndNotifications();
    _updateNotification();
  }

  void _scheduleStepEndNotifications() {
    _soundTimer?.cancel();
    _stepEndTimer?.cancel();
    _soundTimer = null;
    _stepEndTimer = null;

    if (!_isPlaying || !_isCountingDown || _stepToken.isEmpty) return;

    final remainingMilliseconds = _currentMilliseconds();

    // Comme dans le contrôleur historique, une séquence sonore dont le
    // seuil est déjà dépassé n'est jamais jouée en retard.
    if (_notificationMode == 'sound' &&
        !_soundThresholdsSent.contains(_stepToken)) {
      final soundDelay = remainingMilliseconds - _soundGoOffsetMilliseconds;
      if (soundDelay >= 0) {
        final stepToken = _stepToken;
        _soundThresholdsArmed.add(stepToken);
        _soundTimer = Timer(
          Duration(milliseconds: soundDelay),
          () => _sendSoundThreshold(stepToken),
        );
      }
    } else if (_notificationMode != 'sound') {
      _soundThresholdsArmed.remove(_stepToken);
    }

    if (!_stepEndsSent.contains(_stepToken)) {
      final endDelay = remainingMilliseconds < 0 ? 0 : remainingMilliseconds;
      final stepToken = _stepToken;
      _stepEndTimer = Timer(
        Duration(milliseconds: endDelay),
        () => _sendStepEnd(stepToken),
      );
    }
  }

  void _evaluateStepEndNotifications() {
    if (!_isPlaying || !_isCountingDown || _stepToken.isEmpty) return;

    final remainingMilliseconds = _currentMilliseconds();
    if (_notificationMode == 'sound' &&
        _soundThresholdsArmed.contains(_stepToken) &&
        remainingMilliseconds <= _soundGoOffsetMilliseconds) {
      _sendSoundThreshold(_stepToken);
    }
    if (remainingMilliseconds <= 0) _sendStepEnd(_stepToken);
  }

  void _sendSoundThreshold(String stepToken) {
    _soundTimer = null;
    if (!_isPlaying ||
        _notificationMode != 'sound' ||
        stepToken != _stepToken ||
        !_soundThresholdsSent.add(stepToken)) {
      return;
    }
    FlutterForegroundTask.sendDataToMain(<String, Object>{
      'event': sessionNotificationSoundThresholdEvent,
      'stepToken': stepToken,
    });
  }

  void _sendStepEnd(String stepToken) {
    _stepEndTimer = null;
    if (!_isPlaying ||
        stepToken != _stepToken ||
        !_stepEndsSent.add(stepToken)) {
      return;
    }
    FlutterForegroundTask.sendDataToMain(<String, Object>{
      'event': sessionNotificationTimedStepEndedEvent,
      'stepToken': stepToken,
      'notificationMode': _notificationMode,
    });
  }

  // Valeur courante du chrono (millisecondes), recalculée à partir du dernier
  // point de référence reçu. En pause, la valeur reste figée à
  // _baseMilliseconds (aucun temps ne s'écoule alors côté SessionController
  // non plus).
  int _currentMilliseconds() {
    if (!_isPlaying) return _baseMilliseconds;

    final elapsedSincePin =
        DateTime.now().millisecondsSinceEpoch - _pinEpochMillis;
    final milliseconds = _isCountingDown
        ? _baseMilliseconds - elapsedSincePin
        : _baseMilliseconds + elapsedSincePin;

    return _isCountingDown && milliseconds < 0 ? 0 : milliseconds;
  }

  void _updateNotification() {
    final chronoText = formatDuration(
      Duration(milliseconds: _currentMilliseconds()),
    );

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
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _soundTimer?.cancel();
    _stepEndTimer?.cancel();
  }
}
