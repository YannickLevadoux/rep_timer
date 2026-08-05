import 'package:flutter/material.dart';

import '../models/session_checkpoint.dart';
import '../models/training.dart';
import '../services/json_prefs_storage.dart';
import '../services/session_controller.dart';
import '../utils/snack.dart';
import '../validation/business_validation.dart';
import '../widgets/dialogs/comment_dialog.dart';
import '../widgets/dialogs/exit_session_dialog.dart';
import '../widgets/session_finished_view.dart';
import '../widgets/session_running_body.dart';
import 'session_progress.dart';
import '../widgets/dialogs/incomplete_session_dialog.dart';

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
  final TrainingChangesPersistence trainingChangesPersistence;

  // Si fourni, l'écran reprend la séance exactement là où elle en était
  // plutôt que de repartir de la première étape (reprise après une mort
  // de processus par le système).
  final SessionCheckpoint? initialCheckpoint;

  const TrainingSessionScreen({
    super.key,
    required this.training,
    this.initialCheckpoint,
    this.trainingChangesPersistence = TrainingChangesPersistence.persistent,
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
      trainingChangesPersistence: widget.trainingChangesPersistence,
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

  // Empêche l'ouverture simultanée de plusieurs dialogues "Séance
  // incomplète" si le contrôleur notifie plusieurs fois pendant que le
  // dialogue est déjà affiché.
  bool _showingIncompleteDialog = false;

  void _onControllerChanged() {
    // La séance vient de se terminer (auto-complétion du dernier
    // exercice, ou fin anticipée via le menu de sortie) : le
    // clignotement n'a plus lieu d'être. Inoffensif si déjà arrêté.
    if (_controller.finished) {
      _blinkController?.stop();
    } else if (_blinkController != null) {
      // Synchronise le clignotement avec l'état de pause du contrôleur,
      // quelle que soit son origine (bouton pause manuel, ou mise en
      // pause automatique suite à une séance incomplète).
      if (_controller.paused && _blinkController!.isAnimating) {
        _blinkController!.stop();
      } else if (!_controller.paused && !_blinkController!.isAnimating) {
        _blinkController!.repeat(reverse: true);
      }
    }

    // La dernière étape possible vient d'être franchie avec des
    // exercices/pauses restants : le contrôleur s'est mis en pause tout
    // seul, à l'écran de proposer le choix à l'utilisateur.
    if (_controller.pendingIncompleteReview && !_showingIncompleteDialog) {
      _showingIncompleteDialog = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showIncompleteSessionDialog(),
      );
    }

    setState(() {});
  }

  Future<void> _showIncompleteSessionDialog() async {
    if (!mounted) return;

    final choice = await showIncompleteSessionDialog(context);
    _showingIncompleteDialog = false;

    if (!mounted) return;

    switch (choice) {
      case IncompleteSessionChoice.chooseStep:
        // Réutilise l'écran de progression existant : la sélection d'un
        // exercice y relance elle-même la séance (voir
        // SessionController.jumpToStep).
        _openProgress();
        break;
      case IncompleteSessionChoice.finish:
        // Arrêt définitif : le statut Incomplète est déterminé par le
        // contrôleur lui-même à partir de la progression réelle, pas
        // besoin de le préciser ici.
        await _controller.finishSession(earlyExit: true);
        break;
      case null:
        // Ne devrait pas arriver (dialogue non-annulable), mais laisse
        // la séance en pause plutôt que de risquer un état incohérent.
        break;
    }
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
  // mise à jour est reportée sur le contrôleur, qui applique la politique
  // de persistance choisie par l'écran appelant.
  Future<void> _startEditComment() async {
    final result = await showCommentDialog(
      context,
      initialComment: _controller.currentStep.item.comment ?? '',
    );

    // Annulé (bouton ou fermeture du dialogue) : on ne touche à rien, le
    // commentaire précédent est conservé tel quel.
    if (result == null) return;

    try {
      await _controller.updateComment(result);
    } on BusinessValidationException {
      // Le dialogue applique le même contrat. Ce garde-fou protège aussi les
      // appels programmatiques et laisse la valeur précédente intacte.
      return;
    } on StorageMutationBlockedException {
      if (!mounted) return;
      showSnack(
        context,
        "Commentaire non enregistré : les séances stockées n'ont pas pu "
        "être lues intégralement.",
      );
    }
  }

  Future<void> _showExitMenu() async {
    final choice = await showExitSessionDialog(context);

    if (!mounted) return;

    switch (choice) {
      case ExitSessionChoice.finish:
        // Arrêt immédiat. Le statut réellement enregistré (Terminée ou
        // Incomplète) dépend uniquement de la progression réelle — voir
        // SessionController.finishSession — pas du simple fait d'avoir
        // cliqué ce bouton.
        await _controller.finishSession(earlyExit: true);
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
        appBar: AppBar(
          title: Text(
            widget.training.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
          title: Text(
            widget.training.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
            notificationMode: _controller.notificationMode,
            blinkOpacity: _blinkOpacity,
            onPrevious: _controller.goToPrevious,
            onNext: _controller.goToNext,
            onComplete: _controller.completeCurrentStep,
            onTogglePause: _handleTogglePause,
            onEditComment: _startEditComment,
            onCycleNotificationMode: _controller.cycleNotificationMode,
          ),
        ),
      ),
    );
  }
}
