import 'dart:async';

import 'session_controller_composition.dart';
import 'session_controller_runtime.dart';
import 'session_navigation_coordinator.dart';

export 'session_controller_runtime.dart'
    show SessionTickCancel, SessionTickSchedule;

/// Progression, navigation et finalisation d'une séance active.
abstract class SessionControllerBase extends SessionControllerRuntime {
  SessionControllerBase({
    required super.composition,
    super.trainingChangesPersistence,
    super.tickSchedule,
  }) {
    _navigation = SessionNavigationCoordinator(
      progress: composition.progress,
      clock: composition.clock,
      timedGroups: composition.timedGroups,
      notifications: notifications,
      onResume: () => setPaused(false),
      onChanged: notifyIfActive,
      saveCheckpoint: saveCheckpoint,
    );
  }

  late final SessionNavigationCoordinator _navigation;
  bool _finishing = false;

  @override
  bool get canSaveCheckpoint => !composition.progress.finished && !_finishing;

  @override
  void handleTimedStepEnded() {
    if (composition.progress.finished || composition.clock.paused) return;
    composition.clock.captureBackgroundStepEnd();
    completeCurrentStep();
  }

  @override
  void handleRunningTick() {
    if (composition.clock.paused ||
        composition.progress.finished ||
        _finishing) {
      return;
    }
    final duration = composition.progress.currentStep.item.duration;
    final elapsed = composition.clock.stepElapsed;
    if (duration != null && elapsed >= duration) {
      completeCurrentStep();
    } else {
      composition.amrapSnapshot;
      notifyIfActive();
    }
  }

  void completeCurrentStep() {
    if (preparation.preparing || composition.progress.finished || _finishing) {
      return;
    }
    final amrap = composition.amrapSnapshot;
    if (amrap != null && amrap.activeRemaining > Duration.zero) return;
    composition.timedGroups.completeCurrent(
      index: composition.progress.currentIndex,
      stepElapsed: composition.clock.stepElapsed,
    );
    notifications.notifyTimedStepCompletionFallback();
    composition.progress.recordCurrentStepDuration(
      composition.clock.stepElapsed,
    );
    switch (composition.progress.completeCurrentStep()) {
      case SessionStepCompletion.advanced:
        composition.clock.resetStep();
        notifications.handleNaturalStepAdvanced();
        notifyIfActive();
        unawaited(saveCheckpoint());
      case SessionStepCompletion.sessionCompleted:
        unawaited(finishSession());
      case SessionStepCompletion.needsReview:
        setPaused(true);
        unawaited(saveCheckpoint());
    }
  }

  Future<void> finishSession({bool earlyExit = false}) async {
    if (preparation.preparing || composition.progress.finished || _finishing) {
      return;
    }
    _finishing = true;
    if (earlyExit) unawaited(notifications.stop(cancelSound: true));
    composition.progress.recordCurrentStepDuration(
      composition.clock.stepElapsed,
    );
    stopTicker();
    composition.clock.stop();
    try {
      await composition.disableWakelock();
      await composition.completeSession();
      await notifications.stop();
      composition.progress.markFinished();
      notifyIfActive();
    } finally {
      if (!composition.progress.finished) _finishing = false;
    }
  }

  bool jumpToStep(int index, {bool restartAmrap = false}) {
    if (preparation.preparing ||
        !composition.progress.canJumpTo(index) ||
        composition.progress.finished ||
        _finishing) {
      return false;
    }
    return _navigation.jumpTo(index, restartAmrap: restartAmrap);
  }

  bool goToPrevious({bool restartAmrap = false}) => jumpToStep(
    composition.progress.currentIndex - 1,
    restartAmrap: restartAmrap,
  );

  bool goToNext({bool restartAmrap = false}) => jumpToStep(
    composition.progress.currentIndex + 1,
    restartAmrap: restartAmrap,
  );

  Future<void> abandon() {
    notifications.stopPreparationSignal();
    unawaited(notifications.stop(cancelSound: true));
    return composition.completion.clearCheckpoint();
  }
}
