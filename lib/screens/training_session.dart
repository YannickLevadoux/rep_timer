import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/history_step_entry.dart';
import '../models/session_checkpoint.dart';
import '../models/session_step.dart';
import '../models/training.dart';
import '../models/training_history_entry.dart';
import '../models/training_item.dart';
import '../services/session_checkpoint_storage.dart';
import '../services/training_history_storage.dart';
import '../services/training_storage.dart';
import '../utils/exercise_icons.dart';
import '../utils/formatters.dart';
import 'session_progress.dart';

/// Écran principal d'exécution d'une séance : empêche la mise en veille,
/// fait défiler les exercices dans l'ordre (avec répétition des groupes),
/// et enregistre la séance dans l'historique une fois terminée.
class TrainingSessionScreen extends StatefulWidget {
  final Training training;

  // Si fourni, l'écran reprend la séance exactement là où elle en était
  // plutôt que de repartir de la première étape (reprise après une mort
  // de processus par le système).
  final SessionCheckpoint? initialCheckpoint;

  const TrainingSessionScreen({
    super.key,
    required this.training,
    this.initialCheckpoint,
  });

  @override
  State<TrainingSessionScreen> createState() => _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends State<TrainingSessionScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final List<SessionStep> _steps;
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

  final SessionCheckpointStorage _checkpointStorage =
      SessionCheckpointStorage();

  // Anime le clignotement (nom + icône) de l'exercice en cours. Nullable
  // car non créé si la séance ne contient aucune étape.
  AnimationController? _blinkController;

  // Le commentaire s'édite désormais dans un Dialog dédié (voir
  // _startEditComment), plus d'état d'édition inline à maintenir ici.
  final TrainingStorage _trainingStorage = TrainingStorage();

  Duration get _globalElapsed =>
      _globalElapsedOffset + _globalStopwatch.elapsed;
  Duration get _stepElapsed => _stepElapsedOffset + _stepStopwatch.elapsed;

  // Horodatage du dernier passage en arrière-plan (processus non tué) ;
  // sert à calculer le temps réellement écoulé au retour, via l'heure
  // système plutôt qu'un chronomètre qui peut se figer pendant la mise
  // en veille du téléphone.
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _steps = buildSessionSteps(widget.training);

    // Tente de reprendre depuis un checkpoint, uniquement s'il correspond
    // bien à cette séance (nombre d'étapes inchangé depuis la sauvegarde ;
    // sinon la séance a été modifiée entre-temps et on repart proprement
    // de zéro plutôt que de risquer un état incohérent).
    final checkpoint = widget.initialCheckpoint;
    final canRestore =
        checkpoint != null &&
        checkpoint.completed.length == _steps.length &&
        checkpoint.stepActualDurations.length == _steps.length &&
        checkpoint.currentIndex >= 0 &&
        checkpoint.currentIndex < _steps.length;

    if (canRestore) {
      _currentIndex = checkpoint.currentIndex;
      _completed = List.of(checkpoint.completed);
      _stepActualDurations = List.of(checkpoint.stepActualDurations);
      _globalElapsedOffset = checkpoint.globalElapsed;
      _stepElapsedOffset = checkpoint.stepElapsed;
      _paused = checkpoint.paused;

      // Rattrape le temps réellement écoulé entre la sauvegarde du
      // checkpoint et cette reprise (ex : processus tué par le système
      // puis relancé), en se basant sur l'heure système (DateTime.now())
      // et non sur un chronomètre qui n'a pas pu tourner entre-temps.
      // Si la séance était en pause au moment de la sauvegarde, aucun
      // temps ne doit être rattrapé.
      if (!_paused) {
        final backgroundGap = DateTime.now().difference(checkpoint.savedAt);
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

    WakelockPlus.enable();

    if (!_paused) {
      _globalStopwatch.start();
      _stepStopwatch.start();
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (_paused) {
      _blinkController!.value = 1;
    } else {
      _blinkController!.repeat(reverse: true);
    }

    // Assure qu'un checkpoint valide et à jour existe dès le début de
    // l'écran (corrige aussi silencieusement un éventuel checkpoint
    // invalide/obsolète en le remplaçant par l'état réellement démarré).
    _saveCheckpoint();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _blinkController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_finished) return;

    if (state == AppLifecycleState.paused) {
      _handleAppBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  // L'app quitte le premier plan : on fige les chronomètres tout de
  // suite (on ne veut pas dépendre du comportement de l'horloge du
  // système pendant la mise en veille), et on note l'heure système pour
  // pouvoir rattraper l'écart réel au retour. On sauvegarde aussi le
  // checkpoint immédiatement : le processus peut être tué à tout moment
  // une fois en arrière-plan, sans autre avertissement.
  void _handleAppBackgrounded() {
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
  // pris en charge dans initState) : on rattrape le temps réellement
  // écoulé pendant l'arrière-plan via l'heure système, puis on relance
  // les chronomètres.
  void _handleAppResumed() {
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;

    if (backgroundedAt == null || _paused) return;

    final backgroundGap = DateTime.now().difference(backgroundedAt);

    setState(() {
      if (backgroundGap > Duration.zero) {
        _globalElapsedOffset += backgroundGap;
        _stepElapsedOffset += backgroundGap;
      }
      _globalStopwatch.start();
      _stepStopwatch.start();
    });

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
    _stepActualDurations[_currentIndex] = _stepElapsed;
  }

  Future<void> _saveCheckpoint() async {
    if (_finished) return;

    await _checkpointStorage.saveCheckpoint(
      SessionCheckpoint(
        trainingId: widget.training.id,
        currentIndex: _currentIndex,
        completed: List.of(_completed),
        globalElapsed: _globalElapsed,
        stepElapsed: _stepElapsed,
        paused: _paused,
        savedAt: DateTime.now(),
        stepActualDurations: List.of(_stepActualDurations),
      ),
    );
  }

  SessionStep get _currentStep => _steps[_currentIndex];

  // Animation de clignotement partagée : réutilisée pour l'icône, le nom
  // et le commentaire de l'exercice en cours (ici et sur l'écran de
  // progression), afin qu'ils restent synchronisés.
  Animation<double> get _blinkOpacity => _blinkController != null
      ? Tween<double>(begin: 1, end: 0.35).animate(
          CurvedAnimation(parent: _blinkController!, curve: Curves.easeInOut),
        )
      : const AlwaysStoppedAnimation(1);

  void _onTick() {
    if (_paused || _finished) return;

    final duration = _currentStep.item.duration;

    if (duration != null && _stepElapsed >= duration) {
      _completeCurrentStep();
    } else {
      // Rafraîchit l'affichage du chronomètre global / compte à rebours.
      setState(() {});
    }
  }

  void _completeCurrentStep() {
    if (_finished) return;

    _recordCurrentStepDuration();

    setState(() {
      _completed[_currentIndex] = true;

      if (_currentIndex + 1 < _steps.length) {
        _currentIndex++;
        _stepElapsedOffset = Duration.zero;
        _stepStopwatch
          ..stop()
          ..reset();
        if (!_paused) _stepStopwatch.start();
      } else {
        _finishSession();
      }
    });

    if (!_finished) _saveCheckpoint();
  }

  Future<void> _finishSession({
    TrainingSessionStatus status = TrainingSessionStatus.completed,
  }) async {
    if (_finished) return;

    // Couvre le cas "Terminer la session" (fin anticipée), qui ne passe
    // pas par _completeCurrentStep : sans cela, le temps partiel de
    // l'étape en cours au moment de l'arrêt ne serait jamais enregistré.
    // Idempotent si déjà appelé juste avant depuis _completeCurrentStep.
    _recordCurrentStepDuration();

    _ticker?.cancel();
    _blinkController?.stop();
    _globalStopwatch.stop();
    _stepStopwatch.stop();
    await WakelockPlus.disable();

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
        trainingId: widget.training.id,
        trainingName: widget.training.name,
        date: DateTime.now(),
        totalDuration: _globalElapsed,
        status: status,
        steps: stepEntries,
      );

      await TrainingHistoryStorage().addEntry(entry);
    }

    // La séance est close (normalement ou de façon anticipée) : plus
    // rien à reprendre, on supprime le checkpoint.
    await _checkpointStorage.clearCheckpoint();

    if (!mounted) return;
    setState(() => _finished = true);
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;

      if (_paused) {
        _globalStopwatch.stop();
        _stepStopwatch.stop();
        _blinkController?.stop();
      } else {
        _globalStopwatch.start();
        _stepStopwatch.start();
        _blinkController?.repeat(reverse: true);
      }
    });

    _saveCheckpoint();
  }

  // Navigation manuelle : ne modifie jamais le statut "terminé" des
  // exercices, contrairement à _completeCurrentStep. Seul l'index courant
  // (et le minuteur de l'étape) change.
  void _jumpToStep(int index) {
    if (index < 0 || index >= _steps.length) return;

    _recordCurrentStepDuration();

    setState(() {
      _currentIndex = index;
      _stepElapsedOffset = Duration.zero;
      _stepStopwatch
        ..stop()
        ..reset();
      if (!_paused) _stepStopwatch.start();
    });

    _saveCheckpoint();
  }

  void _goToPrevious() => _jumpToStep(_currentIndex - 1);

  void _goToNext() => _jumpToStep(_currentIndex + 1);

  // Ouvre le commentaire dans un Dialog positionné en haut de l'écran :
  // Valider/Annuler restent ainsi toujours visibles même quand le clavier
  // Android est affiché, sans avoir besoin de faire défiler l'écran.
  Future<void> _startEditComment() async {
    final controller = TextEditingController(
      text: _currentStep.item.comment ?? '',
    );
    final focusNode = FocusNode();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Commentaire",
                  style: Theme.of(dialogContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  maxLines: 3,
                  minLines: 1,
                  // Comportement par défaut d'un champ multiligne : la
                  // touche Entrée insère un retour à la ligne, inchangé.
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Poids, intensité...",
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text("Annuler"),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext, controller.text),
                      child: const Text("Valider"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    controller.dispose();
    focusNode.dispose();

    // Annulé (bouton ou fermeture du dialogue) : on ne touche à rien, le
    // commentaire précédent est conservé tel quel.
    if (result == null) return;

    final trimmed = result.trim();

    setState(() {
      _currentStep.item.comment = trimmed.isEmpty ? null : trimmed;
    });

    // Même mécanisme de sauvegarde locale que le reste de l'application :
    // widget.training référence les mêmes objets ExerciseGroup/TrainingItem
    // que ceux stockés, donc la mise à jour est persistée immédiatement et
    // réutilisée lors des prochaines séances.
    await _trainingStorage.addOrUpdateTraining(widget.training);
  }

  // Menu affiché sur le bouton Retour pendant l'exécution d'une séance :
  // Continuer / Terminer la session (incomplète, enregistrée) / Abandonner
  // (aucune trace conservée).
  Future<void> _showExitMenu() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Quitter la séance ?"),
          content: const Text("Que souhaitez-vous faire ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'continue'),
              child: const Text("Continuer la séance"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'finish'),
              child: const Text("Terminer la session"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(context, 'abandon'),
              child: const Text("Abandonner"),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    switch (choice) {
      case 'finish':
        // Arrêt immédiat, enregistrement en historique avec le statut
        // "Incomplète", puis affichage du même écran de fin que la
        // séance normale (aucun changement sur cet écran).
        await _finishSession(status: TrainingSessionStatus.incomplete);
        break;
      case 'abandon':
        // Quitte immédiatement, aucun enregistrement dans l'historique,
        // et aucune trace ne doit permettre de reprendre cette séance.
        await _checkpointStorage.clearCheckpoint();
        if (!mounted) return;
        Navigator.pop(context);
        break;
      case 'continue':
      default:
        // Le menu se ferme simplement ; la séance reprend exactement là
        // où elle était (rien à faire : Stopwatch/Timer n'ont jamais été
        // touchés pendant l'affichage du menu).
        break;
    }
  }

  void _openProgress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionProgressScreen(
          steps: _steps,
          completed: _completed,
          currentIndexProvider: () => _currentIndex,
          // Même contrôleur que l'écran d'exécution : le clignotement
          // reste synchronisé et se fige/reprend avec la même pause.
          blinkController: _blinkController!,
          onSelectStep: _jumpToStep,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.training.name)),
        body: const Center(
          child: Text("Cette séance ne contient aucun exercice."),
        ),
      );
    }

    if (_finished) {
      return _buildFinishedView(context);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _showExitMenu();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.training.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: "Progression détaillée",
              onPressed: _openProgress,
            ),
          ],
        ),
        body: SafeArea(child: _buildRunningBody(context)),
      ),
    );
  }

  // Séparateur discret entre sections : ligne fine sur toute la largeur,
  // avec le nom de la section légèrement décalé vers la gauche.
  Widget _sectionDivider(BuildContext context, String label) {
    final color = Theme.of(context).colorScheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          SizedBox(width: 24, child: Divider(color: color, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Divider(color: color, thickness: 1)),
        ],
      ),
    );
  }

  // Prochain élément à exécuter après l'étape courante (ou null si la
  // séance se termine juste après). Recalculé à chaque build : reste donc
  // toujours à jour en temps réel, sans état séparé à synchroniser.
  SessionStep? get _nextStep =>
      _currentIndex + 1 < _steps.length ? _steps[_currentIndex + 1] : null;

  Widget _buildRunningBody(BuildContext context) {
    final step = _currentStep;
    final item = step.item;
    final isDurationBased = item.duration != null;
    final isFreeDuration = item.isFreeDuration;
    final remaining = isDurationBased
        ? (item.duration! - _stepElapsed)
        : Duration.zero;
    final nextStep = _nextStep;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                tooltip: "Exercice précédent",
                onPressed: _currentIndex > 0 ? _goToPrevious : null,
              ),
              const SizedBox(width: 8),
              Text(
                formatDuration(_globalElapsed),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.skip_next),
                tooltip: "Exercice suivant",
                onPressed: _currentIndex < _steps.length - 1 ? _goToNext : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _currentIndex / _steps.length,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text("Exercice ${_currentIndex + 1} / ${_steps.length}"),

          // ---- Section "Prochain" ----
          _sectionDivider(context, "Prochain"),

          Text(
            nextStep == null
                ? "Fin de la session"
                : nextStep.item.type == ItemType.rest
                ? "Pause"
                : nextStep.item.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),

          // ---- Section "En cours" ----
          _sectionDivider(context, "En cours"),

          Text(
            "${step.group.name} — Répétition ${step.roundIndex} / ${step.totalRounds}",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Zone principale : exercice en cours (icône + nom clignotent
          // pendant que la séance tourne, se figent immédiatement en
          // pause). Le commentaire, s'il existe, clignote avec eux.
          FadeTransition(
            opacity: _blinkOpacity,
            child: Column(
              children: [
                Icon(
                  item.type == ItemType.exercise
                      ? iconForExercise(item.iconName)
                      : Icons.timer,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          _buildCommentSection(context, item),

          const SizedBox(height: 24),

          if (isFreeDuration)
            // Durée libre : chronomètre qui monte, indépendant du
            // chronomètre global, démarré automatiquement avec l'étape
            // (voir _stepStopwatch). Même présentation que le compte à
            // rebours du mode Temps pour rester cohérent visuellement.
            Text(
              formatDuration(_stepElapsed),
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            )
          else if (isDurationBased)
            // Compte à rebours très visible : élément le plus proéminent
            // de l'écran.
            Text(
              formatDuration(remaining),
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            )
          else ...[
            Text(
              "× ${item.repetitions ?? 0}",
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _paused ? null : _completeCurrentStep,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                child: Text(
                  "Répétitions effectuées",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],

          if (isFreeDuration) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _paused ? null : _completeCurrentStep,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                child: Text(
                  "Exercice effectué",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _togglePause,
              icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
              label: Text(_paused ? "Reprendre" : "Pause"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection(BuildContext context, TrainingItem item) {
    final comment = item.comment;

    if (comment == null || comment.isEmpty) {
      // Les commentaires sont propres aux exercices : pour une pause,
      // on n'affiche ni commentaire ni lien pour en ajouter un.
      if (item.type == ItemType.rest) {
        return const SizedBox.shrink();
      }

      // Rien à afficher pour le commentaire lui-même ; seul un lien
      // discret permet d'en ajouter un (n'est pas censé clignoter,
      // c'est une action, pas une information sur l'exercice).
      return TextButton.icon(
        onPressed: _startEditComment,
        icon: const Icon(Icons.add_comment, size: 16),
        label: const Text(
          "Ajouter un commentaire",
          style: TextStyle(fontSize: 12),
        ),
      );
    }

    // Commentaire présent : il clignote avec le nom/l'icône (même
    // animation partagée) ; le crayon reste stable et toujours cliquable.
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: FadeTransition(
            opacity: _blinkOpacity,
            child: Text(
              comment,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.edit, size: 16),
          tooltip: "Modifier le commentaire",
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          visualDensity: VisualDensity.compact,
          onPressed: _startEditComment,
        ),
      ],
    );
  }

  Widget _buildFinishedView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.training.name)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                "Séance terminée !",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text("Durée totale : ${formatDuration(_globalElapsed)}"),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text("Retour à l'accueil"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
