import 'package:flutter/material.dart';

import '../models/session_checkpoint.dart';
import '../models/training.dart';
import '../services/json_prefs_storage.dart';
import '../services/session_controller.dart';
import '../utils/snack.dart';
import '../validation/business_validation.dart';
import '../widgets/dialogs/comment_dialog.dart';
import '../widgets/dialogs/exit_session_dialog.dart';
import '../widgets/dialogs/incomplete_session_dialog.dart';
import '../widgets/session_blink_controller.dart';
import '../widgets/training_session_view.dart';
import 'session_progress.dart';

typedef SessionControllerFactory =
    SessionController Function({
      required Training training,
      required SessionCheckpoint? initialCheckpoint,
      required TrainingChangesPersistence trainingChangesPersistence,
    });

class TrainingSessionScreen extends StatefulWidget {
  const TrainingSessionScreen({
    super.key,
    required this.training,
    this.initialCheckpoint,
    this.trainingChangesPersistence = TrainingChangesPersistence.persistent,
    this.controllerFactory,
  });

  final Training training;
  final SessionCheckpoint? initialCheckpoint;
  final TrainingChangesPersistence trainingChangesPersistence;
  @visibleForTesting
  final SessionControllerFactory? controllerFactory;
  @override
  State<TrainingSessionScreen> createState() => _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends State<TrainingSessionScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final SessionController _controller;
  late final SessionBlinkController _blink;
  bool _showingIncompleteDialog = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = (widget.controllerFactory ?? _createController)(
      training: widget.training,
      initialCheckpoint: widget.initialCheckpoint,
      trainingChangesPersistence: widget.trainingChangesPersistence,
    )..addListener(_onControllerChanged);
    _blink = SessionBlinkController(
      vsync: this,
      enabled: _controller.steps.isNotEmpty,
      initiallyPaused: _controller.paused,
    );
  }

  SessionController _createController({
    required Training training,
    required SessionCheckpoint? initialCheckpoint,
    required TrainingChangesPersistence trainingChangesPersistence,
  }) => SessionController(
    training: training,
    initialCheckpoint: initialCheckpoint,
    trainingChangesPersistence: trainingChangesPersistence,
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _blink.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    _blink.synchronize(
      paused: _controller.paused,
      finished: _controller.finished,
    );
    if (_controller.pendingIncompleteReview && !_showingIncompleteDialog) {
      _showingIncompleteDialog = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _reviewIncompleteSession(),
      );
    }
    setState(() {});
  }

  Future<void> _reviewIncompleteSession() async {
    if (!mounted) return;
    final choice = await showIncompleteSessionDialog(context);
    _showingIncompleteDialog = false;
    if (!mounted) return;
    if (choice == IncompleteSessionChoice.chooseStep) {
      _openProgress();
    } else if (choice == IncompleteSessionChoice.finish) {
      await _controller.finishSession(earlyExit: true);
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

  Future<void> _editComment() async {
    final result = await showCommentDialog(
      context,
      initialComment: _controller.currentStep.item.comment ?? '',
    );
    if (result == null) return;
    try {
      await _controller.updateComment(result);
    } on BusinessValidationException {
      return;
    } on StorageMutationBlockedException {
      if (!mounted) return;
      showSnack(
        context,
        "Commentaire non enregistré : les séances stockées n'ont pas pu "
        'être lues intégralement.',
      );
    }
  }

  Future<void> _showExitMenu() async {
    final choice = await showExitSessionDialog(context);
    if (!mounted) return;
    if (choice == ExitSessionChoice.finish) {
      await _controller.finishSession(earlyExit: true);
    } else if (choice == ExitSessionChoice.abandon) {
      await _controller.abandon();
      if (mounted) Navigator.pop(context);
    }
  }

  void _openProgress() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SessionProgressScreen(
          steps: _controller.steps,
          completed: _controller.completed,
          currentIndexProvider: () => _controller.currentIndex,
          blinkController: _blink.animationController!,
          onSelectStep: _controller.jumpToStep,
        ),
      ),
    );
  }

  void _backHome() => Navigator.popUntil(context, (route) => route.isFirst);

  @override
  Widget build(BuildContext context) {
    final view = TrainingSessionView(
      trainingName: widget.training.name,
      finished: _controller.finished,
      totalDuration: _controller.globalElapsed,
      onBackHome: _backHome,
      step: _controller.steps.isEmpty ? null : _controller.currentStep,
      nextStep: _controller.steps.isEmpty ? null : _controller.nextStep,
      currentIndex: _controller.currentIndex,
      totalSteps: _controller.steps.length,
      globalElapsed: _controller.globalElapsed,
      stepElapsed: _controller.stepElapsed,
      paused: _controller.paused,
      notificationMode: _controller.notificationMode,
      blinkOpacity: _blink.opacity,
      onPrevious: _controller.goToPrevious,
      onNext: _controller.goToNext,
      onComplete: _controller.completeCurrentStep,
      onTogglePause: _controller.togglePause,
      onEditComment: _editComment,
      onCycleNotificationMode: _controller.cycleNotificationMode,
      onOpenProgress: _openProgress,
    );
    if (_controller.steps.isEmpty || _controller.finished) return view;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _showExitMenu();
      },
      child: view,
    );
  }
}
