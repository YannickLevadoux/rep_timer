import 'package:flutter/material.dart';

import '../models/notification_mode.dart';
import '../models/session_step.dart';
import 'session_finished_view.dart';
import 'session_running_body.dart';

/// Vue présentative des états vide, actif et terminé d'une séance.
class TrainingSessionView extends StatelessWidget {
  const TrainingSessionView({
    super.key,
    required this.trainingName,
    required this.finished,
    required this.totalDuration,
    required this.onBackHome,
    this.step,
    this.nextStep,
    this.currentIndex = 0,
    this.totalSteps = 0,
    this.globalElapsed = Duration.zero,
    this.stepElapsed = Duration.zero,
    this.paused = false,
    this.notificationMode = NotificationMode.none,
    this.blinkOpacity = const AlwaysStoppedAnimation(1),
    this.onPrevious = _noop,
    this.onNext = _noop,
    this.onComplete = _noop,
    this.onTogglePause = _noop,
    this.onEditComment = _noop,
    this.onCycleNotificationMode = _noop,
    this.onOpenProgress = _noop,
  });

  final String trainingName;
  final bool finished;
  final Duration totalDuration;
  final VoidCallback onBackHome;
  final SessionStep? step;
  final SessionStep? nextStep;
  final int currentIndex;
  final int totalSteps;
  final Duration globalElapsed;
  final Duration stepElapsed;
  final bool paused;
  final NotificationMode notificationMode;
  final Animation<double> blinkOpacity;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onComplete;
  final VoidCallback onTogglePause;
  final VoidCallback onEditComment;
  final VoidCallback onCycleNotificationMode;
  final VoidCallback onOpenProgress;

  @override
  Widget build(BuildContext context) {
    if (step == null) return _emptyView();
    if (finished) {
      return SessionFinishedView(
        trainingName: trainingName,
        totalDuration: totalDuration,
        onBackHome: onBackHome,
      );
    }
    return _runningView();
  }

  Widget _emptyView() {
    return Scaffold(
      appBar: _appBar(),
      body: const Center(
        child: Text('Cette séance ne contient aucun exercice.'),
      ),
    );
  }

  Widget _runningView() {
    return Scaffold(
      appBar: _appBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: 'Progression détaillée',
            onPressed: onOpenProgress,
          ),
        ],
      ),
      body: SafeArea(
        child: SessionRunningBody(
          step: step!,
          nextStep: nextStep,
          currentIndex: currentIndex,
          totalSteps: totalSteps,
          globalElapsed: globalElapsed,
          stepElapsed: stepElapsed,
          paused: paused,
          notificationMode: notificationMode,
          blinkOpacity: blinkOpacity,
          onPrevious: onPrevious,
          onNext: onNext,
          onComplete: onComplete,
          onTogglePause: onTogglePause,
          onEditComment: onEditComment,
          onCycleNotificationMode: onCycleNotificationMode,
        ),
      ),
    );
  }

  AppBar _appBar({List<Widget>? actions}) {
    return AppBar(
      title: Text(trainingName, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: actions,
    );
  }
}

void _noop() {}
