import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/session_step.dart';
import '../models/training.dart';
import '../models/training_history_entry.dart';
import '../models/training_item.dart';
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

  const TrainingSessionScreen({super.key, required this.training});

  @override
  State<TrainingSessionScreen> createState() => _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends State<TrainingSessionScreen>
    with SingleTickerProviderStateMixin {
  late final List<SessionStep> _steps;
  late final List<bool> _completed;

  int _currentIndex = 0;
  bool _paused = false;
  bool _finished = false;
  bool _historySaved = false; // garantit un seul enregistrement historique

  // Stopwatch gère nativement l'accumulation du temps écoulé pendant les
  // phases "start" et l'arrêt pendant les phases "stop" : parfait pour
  // gérer pause/reprise sans recalcul manuel de timestamps.
  final Stopwatch _globalStopwatch = Stopwatch();
  final Stopwatch _stepStopwatch = Stopwatch();
  Timer? _ticker;

  // Anime le clignotement (nom + icône) de l'exercice en cours. Nullable
  // car non créé si la séance ne contient aucune étape.
  AnimationController? _blinkController;

  // Édition du commentaire de l'exercice en cours (pas de blocage sur les
  // autres champs, uniquement le commentaire, comme demandé).
  bool _editingComment = false;
  TextEditingController? _commentController;
  final TrainingStorage _trainingStorage = TrainingStorage();

  @override
  void initState() {
    super.initState();

    _steps = buildSessionSteps(widget.training);
    _completed = List.filled(_steps.length, false);

    if (_steps.isEmpty) {
      _finished = true;
      return;
    }

    WakelockPlus.enable();

    _globalStopwatch.start();
    _stepStopwatch.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _blinkController?.dispose();
    _commentController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  SessionStep get _currentStep => _steps[_currentIndex];

  // Animation de clignotement partagée : réutilisée pour l'icône, le nom
  // et le commentaire de l'exercice en cours (ici et sur l'écran de
  // progression), afin qu'ils restent synchronisés.
  Animation<double> get _blinkOpacity =>
      _blinkController != null
          ? Tween<double>(begin: 1, end: 0.35).animate(
              CurvedAnimation(parent: _blinkController!, curve: Curves.easeInOut),
            )
          : const AlwaysStoppedAnimation(1);

  void _onTick() {
    if (_paused || _finished) return;

    final duration = _currentStep.item.duration;

    if (duration != null && _stepStopwatch.elapsed >= duration) {
      _completeCurrentStep();
    } else {
      // Rafraîchit l'affichage du chronomètre global / compte à rebours.
      setState(() {});
    }
  }

  void _completeCurrentStep() {
    if (_finished) return;

    setState(() {
      _completed[_currentIndex] = true;

      if (_currentIndex + 1 < _steps.length) {
        _currentIndex++;
        _editingComment = false;
        _stepStopwatch
          ..stop()
          ..reset();
        if (!_paused) _stepStopwatch.start();
      } else {
        _finishSession();
      }
    });
  }

  Future<void> _finishSession({
    TrainingSessionStatus status = TrainingSessionStatus.completed,
  }) async {
    if (_finished) return;

    _ticker?.cancel();
    _blinkController?.stop();
    _globalStopwatch.stop();
    _stepStopwatch.stop();
    await WakelockPlus.disable();

    if (!_historySaved) {
      _historySaved = true;

      final entry = TrainingHistoryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        trainingId: widget.training.id,
        trainingName: widget.training.name,
        date: DateTime.now(),
        totalDuration: _globalStopwatch.elapsed,
        status: status,
      );

      await TrainingHistoryStorage().addEntry(entry);
    }

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
  }

  // Navigation manuelle : ne modifie jamais le statut "terminé" des
  // exercices, contrairement à _completeCurrentStep. Seul l'index courant
  // (et le minuteur de l'étape) change.
  void _jumpToStep(int index) {
    if (index < 0 || index >= _steps.length) return;

    setState(() {
      _currentIndex = index;
      _editingComment = false; // on quitte l'exercice, on abandonne l'édition en cours
      _stepStopwatch
        ..stop()
        ..reset();
      if (!_paused) _stepStopwatch.start();
    });
  }

  void _goToPrevious() => _jumpToStep(_currentIndex - 1);

  void _goToNext() => _jumpToStep(_currentIndex + 1);

  void _startEditComment() {
    _commentController?.dispose();
    _commentController = TextEditingController(
      text: _currentStep.item.comment ?? '',
    );
    setState(() => _editingComment = true);
  }

  void _cancelEditComment() {
    // Abandonne les modifications : on ne touche pas à item.comment,
    // on referme simplement le mode édition.
    setState(() => _editingComment = false);
  }

  Future<void> _saveComment() async {
    final text = _commentController?.text.trim() ?? '';

    setState(() {
      _currentStep.item.comment = text.isEmpty ? null : text;
      _editingComment = false;
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
        // Quitte immédiatement, aucun enregistrement dans l'historique.
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
      onPopInvoked: (didPop) async {
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
    final remaining =
        isDurationBased ? (item.duration! - _stepStopwatch.elapsed) : Duration.zero;
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
                formatDuration(_globalStopwatch.elapsed),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.skip_next),
                tooltip: "Exercice suivant",
                onPressed:
                    _currentIndex < _steps.length - 1 ? _goToNext : null,
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
              formatDuration(_stepStopwatch.elapsed),
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
              ),
            )
          else if (isDurationBased)
            // Compte à rebours très visible : élément le plus proéminent
            // de l'écran.
            Text(
              formatDuration(remaining),
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
              ),
            )
          else ...[
            Text(
              "× ${item.repetitions ?? 0}",
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
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
    if (_editingComment) {
      // Mode édition : ne clignote pas (formulaire statique), avec
      // Valider / Annuler comme demandé.
      return Column(
        children: [
          TextField(
            controller: _commentController,
            maxLines: 3,
            minLines: 1,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Poids, intensité...",
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _cancelEditComment,
                child: const Text("Annuler"),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _saveComment,
                child: const Text("Valider"),
              ),
            ],
          ),
        ],
      );
    }

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
              Text(
                "Durée totale : ${formatDuration(_globalStopwatch.elapsed)}",
              ),
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