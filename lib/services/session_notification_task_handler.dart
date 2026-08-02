import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Identifiant du bouton "Pause" de la notification étendue. Son appui
/// doit être traité par [SessionController] (isolate principal), seul à
/// connaître l'état réel de la séance — voir [SessionNotificationTaskHandler].
const String sessionNotificationPauseButtonId = 'pause';

/// Identifiant du bouton "Voir la séance" de la notification étendue.
/// Contrairement au bouton Pause, il ne nécessite aucune donnée de
/// [SessionController] : ouvrir l'application suffit, donc traité
/// entièrement ici, sans aller-retour vers l'isolate principal.
const String sessionNotificationOpenButtonId = 'open';

/// Point d'entrée du Foreground Service : fonction de callback exigée par
/// flutter_foreground_task, exécutée dans un isolate séparé de celui de
/// l'UI (voir la doc du plugin). Doit rester top-level avec l'annotation
/// `vm:entry-point` pour être atteignable depuis ce nouvel isolate.
@pragma('vm:entry-point')
void sessionNotificationTaskHandlerCallback() {
  FlutterForegroundTask.setTaskHandler(SessionNotificationTaskHandler());
}

/// Gestionnaire du Foreground Service, volontairement minimal : toute la
/// logique de séance (chronomètre, détection de fin d'étape, son,
/// vibration) continue de vivre dans `SessionController`, sur l'isolate
/// principal — jamais dupliquée ici. Ce isolate ne fait que garder le
/// service actif et relayer les interactions avec la notification :
/// - bouton "Pause" -> renvoyé à l'isolate principal (seul à pouvoir
///   agir sur la séance en cours) ;
/// - bouton "Voir la séance" / appui sur le corps de la notification ->
///   ramène directement l'application au premier plan, aucune donnée de
///   séance n'étant nécessaire pour cette action.
class SessionNotificationTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Rien à faire ici : le contenu de la notification (texte, icône,
    // boutons) est entièrement piloté par SessionController via
    // FlutterForegroundTask.updateService(...), appelé depuis l'isolate
    // principal à chaque changement pertinent. Ce callback périodique
    // n'est requis que par l'API du plugin (ForegroundTaskEventAction),
    // pas par notre logique métier.
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == sessionNotificationOpenButtonId) {
      FlutterForegroundTask.launchApp();
      return;
    }
    if (id == sessionNotificationPauseButtonId) {
      FlutterForegroundTask.sendDataToMain(id);
    }
  }

  @override
  void onNotificationPressed() {
    // Appui sur le corps de la notification (hors boutons) : même
    // comportement que le bouton "Voir la séance", ramène directement
    // l'application au premier plan.
    FlutterForegroundTask.launchApp();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
