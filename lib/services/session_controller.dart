import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/history_step_entry.dart';
import '../models/notification_mode.dart';
import '../models/session_checkpoint.dart';
import '../models/session_step.dart';
import '../models/training.dart';
import '../models/training_history_entry.dart';
import 'app_settings_storage.dart';
import 'session_checkpoint_storage.dart';
import 'step_end_notification_service.dart';
import 'training_history_storage.dart';
import 'training_storage.dart';

/// Logique d'exécution d'une séance : progression dans les étapes,
/// chronométrage (global + par étape), gestion de la pause, persistance
/// du checkpoint et de l'historique. Isolé de l'écran (voir
/// `training_session.dart`) pour que ce dernier ne s'occupe que de
/// l'affichage ; notifie ses écouteurs (`ChangeNotifier`) à chaque
/// changement d'état pertinent pour l'UI.
class SessionController extends ChangeNotifier {
  SessionController({
    required this.training,
    SessionCheckpoint? initialCheckpoint,
    SessionCheckpointStorage? checkpointStorage,
    TrainingStorage? trainingStorage,
    TrainingHistoryStorage? historyStorage,
    AppSettingsStorage? settingsStorage,
    StepEndNotificationService? notificationService,
    Future<void> Function()? enableWakelock,
    Future<void> Function()? disableWakelock,
  }) : _steps = buildSessionSteps(training),
       _checkpointStorage = checkpointStorage ?? SessionCheckpointStorage(),
       _trainingStorage = trainingStorage ?? TrainingStorage(),
       _historyStorage = historyStorage ?? TrainingHistoryStorage(),
       _settingsStorage = settingsStorage ?? AppSettingsStorage(),
       _notificationService =
           notificationService ?? StepEndNotificationService(),
       _enableWakelock = enableWakelock ?? WakelockPlus.enable,
       _disableWakelock = disableWakelock ?? WakelockPlus.disable {
    // Tente de reprendre depuis un checkpoint, uniquement s'il correspond
    // bien à cette séance (nombre d'étapes inchangé depuis la sauvegarde ;
    // sinon la séance a été modifiée entre-temps et on repart proprement
    // de zéro plutôt que de risquer un état incohérent).
    final canRestore =
        initialCheckpoint != null &&
        initialCheckpoint.completed.length == _steps.length &&
        initialCheckpoint.stepActualDurations.length == _steps.length &&
        initialCheckpoint.currentIndex >= 0 &&
        initialCheckpoint.currentIndex < _steps.length;

    if (canRestore) {
      _currentIndex = initialCheckpoint.currentIndex;
      _completed = List.of(initialCheckpoint.completed);
      _stepActualDurations = List.of(initialCheckpoint.stepActualDurations);
      _globalElapsedOffset = initialCheckpoint.globalElapsed;
      _stepElapsedOffset = initialCheckpoint.stepElapsed;
      _paused = initialCheckpoint.paused;

      // Rattrape le temps réellement écoulé entre la sauvegarde du
      // checkpoint et cette reprise (ex : processus tué par le système
      // puis relancé), en se basant sur l'heure système (DateTime.now())
      // et non sur un chronomètre qui n'a pas pu tourner entre-temps.
      // Si la séance était en pause au moment de la sauvegarde, aucun
      // temps ne doit être rattrapé.
      if (!_paused) {
        final backgroundGap = DateTime.now().difference(
          initialCheckpoint.savedAt,
        );
        if (backgroundGap > Duration.zero) {
          _globalElapsedOffset += backgroundGap;
          _stepElapsedOffset += backgroundGap;
        }
      }
    } else {
      _completed = List.filled(_steps.length, false);
      _stepActualDurations = List.filled(_steps.length, Duration.zero);
    }

    // Configuration de session des notifications : initialisée à partir
    // de la configuration globale (voir AppSettingsStorage), puis
    // totalement indépendante de celle-ci pour le reste de la séance
    // (voir cycleNotificationMode). Chargement asynchrone, comme
    // _saveCheckpoint() ci-dessous : la valeur par défaut (Rien) reste
    // affichée le temps très bref de ce chargement.
    _loadInitialNotificationMode();

    if (_steps.isEmpty) {
      _finished = true;
      return;
    }

    // Initialise les seuils de notification encore à venir pour l'étape
    // de départ, en excluant ceux déjà "dépassés" si on reprend en cours
    // de route (checkpoint restauré avec un temps restant déjà sous 3s,
    // par exemple) : voir _resetNotificationThresholds.
    _resetNotificationThresholds();

    _enableWakelock();

    if (!_paused) {
      _globalStopwatch.start();
      _stepStopwatch.start();
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());

    // Assure qu'un checkpoint valide et à jour existe dès le début
    // (corrige aussi silencieusement un éventuel checkpoint
    // invalide/obsolète en le remplaçant par l'état réellement démarré).
    _saveCheckpoint();
  }

  final Training training;
  final List<SessionStep> _steps;

  late List<bool> _completed;

  // Temps réellement passé sur chaque étape (indexé comme _steps), utilisé
  // pour alimenter le détail de l'historique. Mis à jour à chaque fois
  // qu'on quitte une étape (voir _recordCurrentStepDuration) : 0 tant
  // qu'une étape n'a jamais été atteinte, valeur partielle si interrompue.
  late List<Duration> _stepActualDurations;

  int _currentIndex = 0;
  bool _paused = false;
  bool _finished = false;
  bool _historySaved = false; // garantit un seul enregistrement historique
  bool _disposed = false;

  // Stopwatch gère nativement l'accumulation du temps écoulé pendant les
  // phases "start" et l'arrêt pendant les phases "stop" : parfait pour
  // gérer pause/reprise sans recalcul manuel de timestamps. Les offsets
  // permettent de "précharger" un temps déjà écoulé lors d'une reprise
  // après redémarrage (Stopwatch ne peut pas être réglé directement).
  final Stopwatch _globalStopwatch = Stopwatch();
  final Stopwatch _stepStopwatch = Stopwatch();
  Duration _globalElapsedOffset = Duration.zero;
  Duration _stepElapsedOffset = Duration.zero;
  Timer? _ticker;

  final SessionCheckpointStorage _checkpointStorage;
  final TrainingStorage _trainingStorage;
  final TrainingHistoryStorage _historyStorage;
  final AppSettingsStorage _settingsStorage;
  final StepEndNotificationService _notificationService;
  final Future<void> Function() _enableWakelock;
  final Future<void> Function() _disableWakelock;

  // Configuration de session des notifications (voir le commentaire du
  // constructeur) : ne survit jamais à cette instance de contrôleur,
  // c'est ce qui garantit qu'une nouvelle séance reparte toujours de la
  // configuration globale.
  NotificationMode _notificationMode = NotificationMode.none;

  // Seuils (en secondes restantes) encore à jouer pour l'étape en cours,
  // du plus grand au plus petit ([3, 2, 1, 0] au départ d'une étape à
  // durée). Comparés en "<=" plutôt qu'en égalité stricte dans _onTick,
  // pour rester robustes à la dérive de Timer.periodic (voir _onTick) :
  // sans ça, un tick légèrement en retard peut faire sauter directement
  // le compte à rebours affiché de 3s à 1s, et le seuil "2" ne serait
  // alors jamais atteint par une simple égalité.
  static const List<int> _notificationThresholds = [3, 2, 1, 0];
  List<int> _pendingNotificationThresholds = [];

  // Horodatage du dernier passage en arrière-plan (processus non tué) ;
  // sert à calculer le temps réellement écoulé au retour, via l'heure
  // système plutôt qu'un chronomètre qui peut se figer pendant la mise
  // en veille du téléphone.
  DateTime? _backgroundedAt;

  List<SessionStep> get steps => _steps;
  List<bool> get completed => _completed;
  int get currentIndex => _currentIndex;
  bool get paused => _paused;
  bool get finished => _finished;
  NotificationMode get notificationMode => _notificationMode;

  SessionStep get currentStep => _steps[_currentIndex];

  // Prochain élément à exécuter après l'étape courante (ou null si la
  // séance se termine juste après).
  SessionStep? get nextStep =>
      _currentIndex + 1 < _steps.length ? _steps[_currentIndex + 1] : null;

  Duration get globalElapsed => _globalElapsedOffset + _globalStopwatch.elapsed;
  Duration get stepElapsed => _stepElapsedOffset + _stepStopwatch.elapsed;

  Future<void> _loadInitialNotificationMode() async {
    final mode = await _settingsStorage.loadNotificationMode();
    if (_disposed) return;
    _notificationMode = mode;
    notifyListeners();
  }

  // Contrôle rapide pendant la séance (icône de la section Global) :
  // modifie uniquement la configuration de session, jamais la
  // configuration globale enregistrée dans les Paramètres. Le nouveau
  // mode s'applique immédiatement aux notifications suivantes.
  void cycleNotificationMode() {
    _notificationMode = _notificationMode.next;
    notifyListeners();
  }

  // Recalcule les seuils encore à jouer pour l'étape courante, à partir
  // du temps restant réel à cet instant. Appelé à chaque point où la
  // trajectoire du temps restant peut "sauter" plutôt que de progresser
  // tick par tick : démarrage d'une nouvelle étape, navigation manuelle,
  // retour d'arrière-plan. Un seuil déjà dépassé à ce moment-là (ex :
  // reprise avec 1s restante) n'est jamais ajouté aux seuils en attente,
  // conformément à la règle "pas de rattrapage de notifications
  // manquées lors d'une reprise".
  void _resetNotificationThresholds() {
    final duration = currentStep.item.duration;
    if (duration == null) {
      _pendingNotificationThresholds = [];
      return;
    }

    final remainingSeconds = (duration - stepElapsed).inSeconds;
    _pendingNotificationThresholds = _notificationThresholds
        .where((threshold) => threshold <= remainingSeconds)
        .toList();
  }

  // Déclenche, dans l'ordre décroissant, tous les seuils désormais
  // atteints ou dépassés par [remainingSeconds]. Utilise "<=" plutôt
  // qu'une égalité stricte : si un tick en retard a fait sauter
  // directement de 3s à 1s, les seuils 3 puis 2 sont tous les deux
  // déclenchés à ce tick plutôt que silencieusement perdus (voir le
  // commentaire du champ _pendingNotificationThresholds).
  void _fireDueNotificationThresholds(int remainingSeconds) {
    while (_pendingNotificationThresholds.isNotEmpty &&
        remainingSeconds <= _pendingNotificationThresholds.first) {
      final threshold = _pendingNotificationThresholds.removeAt(0);
      unawaited(
        _notificationService.onTick(
          mode: _notificationMode,
          remainingSeconds: threshold,
        ),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _disableWakelock();
    _notificationService.dispose();
    super.dispose();
  }

  // L'app quitte le premier plan : on fige les chronomètres tout de
  // suite (on ne veut pas dépendre du comportement de l'horloge du
  // système pendant la mise en veille), et on note l'heure système pour
  // pouvoir rattraper l'écart réel au retour. On sauvegarde aussi le
  // checkpoint immédiatement : le processus peut être tué à tout moment
  // une fois en arrière-plan, sans autre avertissement.
  void handleAppBackgrounded() {
    _backgroundedAt = DateTime.now();

    if (!_paused) {
      _globalElapsedOffset += _globalStopwatch.elapsed;
      _stepElapsedOffset += _stepStopwatch.elapsed;
      _globalStopwatch
        ..stop()
        ..reset();
      _stepStopwatch
        ..stop()
        ..reset();
    }

    _saveCheckpoint();
  }

  // Retour au premier plan (processus jamais tué, contrairement au cas
  // pris en charge dans le constructeur) : on rattrape le temps
  // réellement écoulé pendant l'arrière-plan via l'heure système, puis
  // on relance les chronomètres. Aucune notification n'est jouée ici,
  // même si l'écart rattrapé franchit un seuil de déclenchement : seul
  // le tick naturel suivant peut en déclencher une (voir _onTick).
  void handleAppResumed() {
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;

    if (backgroundedAt == null || _paused) return;

    final backgroundGap = DateTime.now().difference(backgroundedAt);

    if (backgroundGap > Duration.zero) {
      _globalElapsedOffset += backgroundGap;
      _stepElapsedOffset += backgroundGap;
    }
    // Recalcule les seuils encore à venir après ce saut de temps : ceux
    // déjà dépassés pendant l'arrière-plan ne doivent pas être rattrapés
    // maintenant (voir _resetNotificationThresholds).
    _resetNotificationThresholds();

    _globalStopwatch.start();
    _stepStopwatch.start();

    notifyListeners();
    _saveCheckpoint();
  }

  // Enregistre le temps réellement passé sur l'étape courante avant de la
  // quitter (complétion, navigation manuelle, ou fin de séance). Appelé à
  // chaque point de sortie d'une étape ; un second appel sur la même
  // étape écrase simplement la valeur précédente (pas d'accumulation en
  // cas de va-et-vient), ce qui reste cohérent avec "temps réellement
  // passé lors du dernier passage".
  void _recordCurrentStepDuration() {
    if (_currentIndex < 0 || _currentIndex >= _stepActualDurations.length) {
      return;
    }
    _stepActualDurations[_currentIndex] = stepElapsed;
  }

  Future<void> _saveCheckpoint() async {
    if (_finished) return;

    await _checkpointStorage.saveCheckpoint(
      SessionCheckpoint(
        trainingId: training.id,
        currentIndex: _currentIndex,
        completed: List.of(_completed),
        globalElapsed: globalElapsed,
        stepElapsed: stepElapsed,
        paused: _paused,
        savedAt: DateTime.now(),
        stepActualDurations: List.of(_stepActualDurations),
      ),
    );
  }

  void _onTick() {
    if (_paused || _finished) return;

    final duration = currentStep.item.duration;

    // Notification de fin naturelle (pause ou exercice Temps
    // uniquement : les exercices en Répétitions/Durée libre n'ont pas de
    // `duration`, donc ne déclenchent jamais rien ici). Le temps restant
    // utilisé est exactement celui affiché à l'écran (voir
    // SessionRunningBody), garantissant la synchronisation.
    if (duration != null) {
      final remainingSeconds = (duration - stepElapsed).inSeconds;
      _fireDueNotificationThresholds(remainingSeconds);
    }

    if (duration != null && stepElapsed >= duration) {
      completeCurrentStep();
    } else {
      // Rafraîchit l'affichage du chronomètre global / compte à rebours.
      notifyListeners();
    }
  }

  void completeCurrentStep() {
    if (_finished) return;

    _recordCurrentStepDuration();

    _completed[_currentIndex] = true;

    if (_currentIndex + 1 < _steps.length) {
      _currentIndex++;
      _stepElapsedOffset = Duration.zero;
      _stepStopwatch
        ..stop()
        ..reset();
      if (!_paused) _stepStopwatch.start();
      _resetNotificationThresholds();
    } else {
      finishSession();
    }

    notifyListeners();

    if (!_finished) _saveCheckpoint();
  }

  Future<void> finishSession({
    TrainingSessionStatus status = TrainingSessionStatus.completed,
  }) async {
    if (_finished) return;

    // Couvre le cas "Terminer la session" (fin anticipée), qui ne passe
    // pas par completeCurrentStep : sans cela, le temps partiel de
    // l'étape en cours au moment de l'arrêt ne serait jamais enregistré.
    // Idempotent si déjà appelé juste avant depuis completeCurrentStep.
    _recordCurrentStepDuration();

    _ticker?.cancel();
    _globalStopwatch.stop();
    _stepStopwatch.stop();
    await _disableWakelock();

    if (!_historySaved) {
      _historySaved = true;

      final stepEntries = [
        for (var i = 0; i < _steps.length; i++)
          HistoryStepEntry(
            groupId: _steps[i].group.id,
            groupName: _steps[i].group.name,
            itemType: _steps[i].item.type,
            itemName: _steps[i].item.name,
            // Snapshot du commentaire tel qu'il est à la fin de la
            // séance. Simplification assumée : si un même exercice
            // revient sur plusieurs tours d'un groupe répété et que son
            // commentaire est modifié entre deux tours, tous les tours
            // affichent la dernière valeur plutôt qu'un historique par
            // tour (cas marginal, non géré pour limiter la complexité).
            comment: _steps[i].item.comment,
            actualDuration: _stepActualDurations[i],
            completed: _completed[i],
          ),
      ];

      final entry = TrainingHistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        trainingId: training.id,
        trainingName: training.name,
        date: DateTime.now(),
        totalDuration: globalElapsed,
        status: status,
        steps: stepEntries,
      );

      await _historyStorage.addEntry(entry);
    }

    // La séance est close (normalement ou de façon anticipée) : plus
    // rien à reprendre, on supprime le checkpoint. La configuration de
    // session des notifications, elle, n'a besoin d'aucune suppression
    // explicite : elle disparaît avec ce contrôleur (voir dispose()).
    await _checkpointStorage.clearCheckpoint();

    if (_disposed) return;
    _finished = true;
    notifyListeners();
  }

  void togglePause() {
    _paused = !_paused;

    if (_paused) {
      _globalStopwatch.stop();
      _stepStopwatch.stop();
    } else {
      _globalStopwatch.start();
      _stepStopwatch.start();
    }

    notifyListeners();
    _saveCheckpoint();
  }

  // Navigation manuelle : ne modifie jamais le statut "terminé" des
  // exercices, contrairement à completeCurrentStep. Seul l'index courant
  // (et le minuteur de l'étape) change. Aucune notification n'est jouée
  // ici (voir _onTick, seul point de déclenchement).
  void jumpToStep(int index) {
    if (index < 0 || index >= _steps.length) return;

    _recordCurrentStepDuration();

    _currentIndex = index;
    _stepElapsedOffset = Duration.zero;
    _stepStopwatch
      ..stop()
      ..reset();
    if (!_paused) _stepStopwatch.start();
    _resetNotificationThresholds();

    notifyListeners();
    _saveCheckpoint();
  }

  void goToPrevious() => jumpToStep(_currentIndex - 1);

  void goToNext() => jumpToStep(_currentIndex + 1);

  // Même mécanisme de sauvegarde locale que le reste de l'application :
  // `training` référence les mêmes objets ExerciseGroup/TrainingItem que
  // ceux stockés, donc la mise à jour est persistée immédiatement et
  // réutilisée lors des prochaines séances.
  Future<void> updateComment(String? comment) async {
    currentStep.item.comment = comment;
    notifyListeners();
    await _trainingStorage.addOrUpdateTraining(training);
  }

  // Abandon de la séance : aucune trace ne doit permettre de la reprendre.
  Future<void> abandon() => _checkpointStorage.clearCheckpoint();
}
