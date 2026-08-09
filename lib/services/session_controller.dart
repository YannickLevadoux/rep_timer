import 'dart:async';

import 'package:flutter/foundation.dart';

import 'session_controller_composition.dart';
import 'session_notification_bridge.dart';

export 'training_changes_persistence.dart';

class SessionController extends ChangeNotifier {
  SessionController({
    required this.training,
    this.trainingChangesPersistence = TrainingChangesPersistence.persistent,
    SessionCheckpoint? initialCheckpoint,
    SessionCheckpointStorage? checkpointStorage,
    TrainingStorage? trainingStorage,
    TrainingHistoryStorage? historyStorage,
    AppSettingsStorage? settingsStorage,
    StepEndNotifier? notificationService,
    NotificationSound? notificationSound,
    SessionNotificationService? foregroundNotificationService,
    Future<void> Function()? enableWakelock,
    Future<void> Function()? disableWakelock,
  }) {
    _composition = SessionControllerComposition(
      training: training,
      initialCheckpoint: initialCheckpoint,
      checkpointStorage: checkpointStorage,
      trainingStorage: trainingStorage,
      historyStorage: historyStorage,
      settingsStorage: settingsStorage,
      notificationService: notificationService,
      notificationSound: notificationSound,
      foregroundNotificationService: foregroundNotificationService,
      enableWakelock: enableWakelock,
      disableWakelock: disableWakelock,
    );
    _notifications = _composition.createNotificationBridge(
      onPausePressed: togglePause,
      onTimedStepEnded: _handleTaskStepEnded,
      onModeChanged: _notifyIfActive,
    );
    if (finished) return;
    _notifications.start();
    unawaited(_composition.enableWakelock());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    unawaited(_saveCheckpoint());
  }

  final Training training;
  final TrainingChangesPersistence trainingChangesPersistence;
  late final SessionControllerComposition _composition;
  late final SessionNotificationBridge _notifications;
  Timer? _ticker;
  bool _finishing = false, _disposed = false;

  List<SessionStep> get steps => _composition.progress.steps;
  List<bool> get completed => _composition.progress.completed;
  int get currentIndex => _composition.progress.currentIndex;
  bool get paused => _composition.clock.paused;
  bool get finished => _composition.progress.finished;
  NotificationMode get notificationMode => _notifications.mode;
  bool get pendingIncompleteReview => _composition.pendingIncompleteReview;
  SessionStep get currentStep => _composition.progress.currentStep;
  SessionStep? get nextStep => _composition.progress.nextStep;
  Duration get globalElapsed => _composition.clock.globalElapsed;
  Duration get stepElapsed => _composition.clock.stepElapsed;
  void cycleNotificationMode() => _notifications.cycleMode();
  void handleAppBackgrounded() {
    if (finished) return;
    _composition.clock.handleAppBackgrounded();
    _notifications.handleAppBackgrounded();
    unawaited(_saveCheckpoint());
  }

  void handleAppResumed() {
    if (finished || !_composition.clock.handleAppResumed()) return;
    _notifications.handleAppResumed();
    _notifyIfActive();
    unawaited(_saveCheckpoint());
  }

  void _handleTaskStepEnded() {
    if (finished || paused) return;
    _composition.clock.captureBackgroundStepEnd();
    completeCurrentStep();
  }

  void _onTick() {
    if (paused || finished || _finishing) return;
    final duration = currentStep.item.duration;
    if (duration != null && stepElapsed >= duration) {
      completeCurrentStep();
    } else {
      _notifyIfActive();
    }
  }

  void completeCurrentStep() {
    if (finished || _finishing) return;
    _notifications.notifyTimedStepCompletionFallback();
    _composition.progress.recordCurrentStepDuration(stepElapsed);
    switch (_composition.progress.completeCurrentStep()) {
      case SessionStepCompletion.advanced:
        _composition.clock.resetStep();
        _notifications.handleNaturalStepAdvanced();
        _notifyIfActive();
        unawaited(_saveCheckpoint());
      case SessionStepCompletion.sessionCompleted:
        unawaited(finishSession());
      case SessionStepCompletion.needsReview:
        _setPaused(true);
        unawaited(_saveCheckpoint());
    }
  }

  Future<void> finishSession({bool earlyExit = false}) async {
    if (finished || _finishing) return;
    _finishing = true;
    if (earlyExit) unawaited(_notifications.stop(cancelSound: true));
    _composition.progress.recordCurrentStepDuration(stepElapsed);
    _ticker?.cancel();
    _composition.clock.stop();
    try {
      await _composition.disableWakelock();
      await _composition.completeSession();
      await _notifications.stop();
      _composition.progress.markFinished();
      _notifyIfActive();
    } finally {
      if (!finished) _finishing = false;
    }
  }

  void togglePause() {
    _setPaused(!paused);
    unawaited(_saveCheckpoint());
  }

  void _setPaused(bool paused) {
    _composition.clock.setPaused(paused);
    _notifications.handlePauseChanged();
    _notifyIfActive();
  }

  void jumpToStep(int index) {
    if (!_composition.progress.canJumpTo(index) || finished || _finishing) {
      return;
    }
    _notifications.prepareManualStepChange();
    _composition.progress.recordCurrentStepDuration(stepElapsed);
    final resumeAfterJump = pendingIncompleteReview && paused;
    _composition.progress.jumpTo(index);
    _composition.clock.resetStep();
    if (resumeAfterJump) {
      _setPaused(false);
    } else {
      _notifications.handleManualStepChanged();
    }
    _notifyIfActive();
    unawaited(_saveCheckpoint());
  }

  void goToPrevious() => jumpToStep(currentIndex - 1);
  void goToNext() => jumpToStep(currentIndex + 1);
  Future<void> updateComment(String? comment) => _composition.comments.update(
    comment: comment,
    currentStep: currentStep,
    steps: steps,
    training: training,
    persistence: trainingChangesPersistence,
    onChanged: _notifyIfActive,
  );

  Future<void> abandon() {
    unawaited(_notifications.stop(cancelSound: true));
    return _composition.completion.clearCheckpoint();
  }

  Future<void> _saveCheckpoint() {
    if (finished || _finishing) return Future<void>.value();
    return _composition.saveCheckpoint();
  }

  void _notifyIfActive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _ticker?.cancel();
    _composition.clock.stop();
    unawaited(_composition.disableWakelock());
    _notifications.dispose();
    super.dispose();
  }
}
