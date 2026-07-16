import 'package:flutter/material.dart';

import '../models/session_checkpoint.dart';
import '../models/training.dart';
import '../models/training_history_entry.dart';
import '../services/session_controller.dart';
import '../widgets/dialogs/comment_dialog.dart';
import '../widgets/dialogs/exit_session_dialog.dart';
import '../widgets/session_finished_view.dart';
import '../widgets/session_running_body.dart';
import 'session_progress.dart';

/// Écran principal d'exécution d'une séance : empêche la mise en veille,
/// fait défiler les exercices dans l'ordre (avec répétition des groupes),
/// et enregistre la séance dans l'historique une fois terminée.
///
/// Toute la logique de progression/chronométrage/persistance vit dans
/// [SessionController] ; cet écran ne s'occupe que de l'affichage et des
/// éléments purement liés au cycle de vie du widget (observateur du
/// cycle de vie de l'app, animation de clignotement).
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
  late final SessionController _controller;

  // Anime le clignotement (nom + icône) de l'exercice en cours. Nullable
  // car non créé si la séance ne contient aucune étape.
  AnimationController? _blinkController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = SessionController(
      training: widget.training,
      initialCheckpoint: widget.initialCheckpoint,
    );
    _controller.addListener(_onControllerChanged);

    if (_controller.steps.isNotEmpty) {
      _blinkController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      );
      if (_controller.paused) {
        _blinkController!.value = 1;
      } else {
        _blinkController!.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _blinkController?.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // La séance vient de se terminer (auto-complétion du dernier
    // exercice, ou fin anticipée via le menu de sortie) : le
    // clignotement n'a plus lieu d'être. Inoffensif si déjà arrêté.
    if (_controller.finished) {
      _blinkController?.stop();
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller.finished) return;

    if (state == AppLifecycleState.paused) {
      _controller.handleAppBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      _controller.handleAppResumed();
    }
  }

  // Animation de clignotement partagée : réutilisée pour l'icône, le nom
  // et le commentaire de l'exercice en cours (ici et sur l'écran de
  // progression), afin qu'ils restent synchronisés.
  Animation<double> get _blinkOpacity => _blinkController != null
      ? Tween<double>(begin: 1, end: 0.35).animate(
          CurvedAnimation(parent: _blinkController!, curve: Curves.easeInOut),
        )
      : const AlwaysStoppedAnimation(1);

  void _handleTogglePause() {
    _controller.togglePause();
    if (_controller.paused) {
      _blinkController?.stop();
    } else {
      _blinkController?.repeat(reverse: true);
    }
  }

  // Ouvre le commentaire dans un Dialog dédié ; en cas de validation, la
  // mise à jour est reportée sur le contrôleur (qui persiste aussitôt).
  Future<void> _startEditComment() async {
    final result = await showCommentDialog(
      context,
      initialComment: _controller.currentStep.item.comment ?? '',
    );

    // Annulé (bouton ou fermeture du dialogue) : on ne touche à rien, le
    // commentaire précédent est conservé tel quel.
    if (result == null) return;

    final trimmed = result.trim();
    await _controller.updateComment(trimmed.isEmpty ? null : trimmed);
  }

  Future<void> _showExitMenu() async {
    final choice = await showExitSessionDialog(context);

    if (!mounted) return;

    switch (choice) {
      case ExitSessionChoice.finish:
        // Arrêt immédiat, enregistrement en historique avec le statut
        // "Incomplète", puis affichage du même écran de fin que la
        // séance normale (aucun changement sur cet écran).
        await _controller.finishSession(
          status: TrainingSessionStatus.incomplete,
        );
        break;
      case ExitSessionChoice.abandon:
        // Quitte immédiatement, aucun enregistrement dans l'historique,
        // et aucune trace ne doit permettre de reprendre cette séance.
        await _controller.abandon();
        if (!mounted) return;
        Navigator.pop(context);
        break;
      case ExitSessionChoice.continueSession:
      case null:
        // Le menu se ferme simplement ; la séance reprend exactement là
        // où elle était (rien à faire : le contrôleur n'a jamais été
        // touché pendant l'affichage du menu).
        break;
    }
  }

  void _openProgress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionProgressScreen(
          steps: _controller.steps,
          completed: _controller.completed,
          currentIndexProvider: () => _controller.currentIndex,
          // Même contrôleur que l'écran d'exécution : le clignotement
          // reste synchronisé et se fige/reprend avec la même pause.
          blinkController: _blinkController!,
          onSelectStep: _controller.jumpToStep,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.training.name)),
        body: const Center(
          child: Text("Cette séance ne contient aucun exercice."),
        ),
      );
    }

    if (_controller.finished) {
      return SessionFinishedView(
        trainingName: widget.training.name,
        totalDuration: _controller.globalElapsed,
        onBackHome: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      );
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
        body: SafeArea(
          child: SessionRunningBody(
            step: _controller.currentStep,
            nextStep: _controller.nextStep,
            currentIndex: _controller.currentIndex,
            totalSteps: _controller.steps.length,
            globalElapsed: _controller.globalElapsed,
            stepElapsed: _controller.stepElapsed,
            paused: _controller.paused,
            blinkOpacity: _blinkOpacity,
            onPrevious: _controller.goToPrevious,
            onNext: _controller.goToNext,
            onComplete: _controller.completeCurrentStep,
            onTogglePause: _handleTogglePause,
            onEditComment: _startEditComment,
          ),
        ),
      ),
    );
  }
}
