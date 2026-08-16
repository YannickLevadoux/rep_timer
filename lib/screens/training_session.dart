import 'dart:async';

import 'package:flutter/material.dart';

import '../models/session_checkpoint.dart';
import '../models/training.dart';
import '../services/session_controller.dart';
import '../widgets/dialogs/amrap_restart_dialog.dart';
import '../widgets/dialogs/incomplete_session_dialog.dart';
import '../widgets/dialogs/session_comment_flow.dart';
import '../widgets/session_blink_controller.dart';
import '../widgets/training_session_view.dart';
import 'session_progress.dart';
import 'session_exit_flow.dart';

class TrainingSessionScreen extends StatefulWidget {
  const TrainingSessionScreen({
    super.key,
    required this.training,
    this.initialCheckpoint,
    this.trainingChangesPersistence = TrainingChangesPersistence.persistent,
    this.controllerFactory,
    this.preSessionCountdownSeconds = 0,
  });

  final Training training;
  final SessionCheckpoint? initialCheckpoint;
  final TrainingChangesPersistence trainingChangesPersistence;
  final int preSessionCountdownSeconds;
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
  late bool _wasPreparing;
  bool _announceSessionStart = false;
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
    _wasPreparing = _controller.preparing;
  }

  SessionController _createController({
    required Training training,
    required SessionCheckpoint? initialCheckpoint,
    required TrainingChangesPersistence trainingChangesPersistence,
  }) => SessionController(
    training: training,
    initialCheckpoint: initialCheckpoint,
    trainingChangesPersistence: trainingChangesPersistence,
    preSessionCountdownSeconds: widget.preSessionCountdownSeconds,
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
      animationsDisabled:
          MediaQuery.maybeOf(context)?.disableAnimations ?? false,
    );
    if (_wasPreparing && !_controller.preparing) {
      _announceSessionStart = true;
    }
    _wasPreparing = _controller.preparing;
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

  Future<void> _editComment() =>
      editCurrentSessionComment(context, _controller);

  void _openProgress() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SessionProgressScreen(
          steps: _controller.steps,
          completed: _controller.completed,
          currentIndexProvider: () => _controller.currentIndex,
          blinkController: _blink.animationController!,
          onBeforeSelectStep: _confirmAmrapRestart,
          onSelectStep: (index) =>
              _controller.jumpToStep(index, restartAmrap: true),
        ),
      ),
    );
  }

  Future<bool> _confirmAmrapRestart(int index) async {
    if (!_controller.requiresAmrapRestart(index)) return true;
    return showAmrapRestartDialog(context);
  }

  Future<void> _jumpToStep(int index) async {
    if (!await _confirmAmrapRestart(index)) return;
    _controller.jumpToStep(index, restartAmrap: true);
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
      onPrevious: () => unawaited(_jumpToStep(_controller.currentIndex - 1)),
      onNext: () => unawaited(_jumpToStep(_controller.currentIndex + 1)),
      onComplete: _controller.completeCurrentStep,
      onTogglePause: _controller.togglePause,
      onEditComment: _editComment,
      onCycleNotificationMode: _controller.cycleNotificationMode,
      onOpenProgress: _openProgress,
      amrap: _controller.amrap,
      onRecordAmrapLap: _controller.recordAmrapLap,
      onUndoAmrapLap: _controller.undoLastAmrapLap,
      preparing: _controller.preparing,
      preparationSeconds: _controller.preparationSeconds,
      onSkipPreparation: _controller.skipPreparation,
      announceSessionStart: _announceSessionStart,
    );
    if (_controller.steps.isEmpty || _controller.finished) return view;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await handleSessionExit(context, _controller);
      },
      child: view,
    );
  }
}
