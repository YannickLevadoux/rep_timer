import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/history_step_entry.dart';
import '../models/session_checkpoint.dart';
import '../models/session_step.dart';
import '../models/training.dart';
import '../models/training_history_entry.dart';
import 'session_checkpoint_storage.dart';
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
    Future<void> Function()? enableWakelock,
    Future<void> Function()? disableWakelock,
  }) : _steps = buildSessionSteps(training),
       _checkpointStorage = checkpointStorage ?? SessionCheckpointStorage(),
       _trainingStorage = trainingStorage ?? TrainingStorage(),
       _historyStorage = historyStorage ?? TrainingHistoryStorage(),
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

    if (_steps.isEmpty) {
      _finished = true;
      return;
    }

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
  final Future<void> Function() _enableWakelock;
  final Future<void> Function() _disableWakelock;

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

  SessionStep get currentStep => _steps[_currentIndex];

  // Prochain élément à exécuter après l'étape courante (ou null si la
  // séance se termine juste après).
  SessionStep? get nextStep =>
      _currentIndex + 1 < _steps.length ? _steps[_currentIndex + 1] : null;

  Duration get globalElapsed => _globalElapsedOffset + _globalStopwatch.elapsed;
  Duration get stepElapsed => _stepElapsedOffset + _stepStopwatch.elapsed;

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _disableWakelock();
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
  // on relance les chronomètres.
  void handleAppResumed() {
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;

    if (backgroundedAt == null || _paused) return;

    final backgroundGap = DateTime.now().difference(backgroundedAt);

    if (backgroundGap > Duration.zero) {
      _globalElapsedOffset += backgroundGap;
      _stepElapsedOffset += backgroundGap;
    }
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
    // rien à reprendre, on supprime le checkpoint.
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
  // (et le minuteur de l'étape) change.
  void jumpToStep(int index) {
    if (index < 0 || index >= _steps.length) return;

    _recordCurrentStepDuration();

    _currentIndex = index;
    _stepElapsedOffset = Duration.zero;
    _stepStopwatch
      ..stop()
      ..reset();
    if (!_paused) _stepStopwatch.start();

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
