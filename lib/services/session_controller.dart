import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/notification_mode.dart';
import '../models/notification_sound.dart';
import '../models/session_checkpoint.dart';
import '../models/session_step.dart';
import '../models/training.dart';
import '../models/training_history_entry.dart';
import 'app_settings_storage.dart';
import 'session_checkpoint_storage.dart';
import 'session_clock.dart';
import 'session_completion_service.dart';
import 'session_notification_coordinator.dart';
import 'session_notification_service.dart';
import 'session_progress_state.dart';
import 'step_end_notification_service.dart';
import 'training_history_storage.dart';
import 'training_storage.dart';

/// Orchestre l'exécution d'une séance et expose son état à l'interface.
/// Les responsabilités de temps, progression, notifications et persistance
/// sont déléguées à des composants spécialisés.
class SessionController extends ChangeNotifier {
  SessionController({
    required this.training,
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
  }) : _trainingStorage = trainingStorage ?? TrainingStorage(),
       _enableWakelock = enableWakelock ?? WakelockPlus.enable,
       _disableWakelock = disableWakelock ?? WakelockPlus.disable {
    final resolvedCheckpointStorage =
        checkpointStorage ?? SessionCheckpointStorage();
    _progress = SessionProgressState(
      training: training,
      checkpoint: initialCheckpoint,
    );

    final restoredCheckpoint = _progress.restoredFromCheckpoint
        ? initialCheckpoint
        : null;
    _clock = SessionClock(
      initialGlobalElapsed: restoredCheckpoint?.globalElapsed ?? Duration.zero,
      initialStepElapsed: restoredCheckpoint?.stepElapsed ?? Duration.zero,
      initiallyPaused: restoredCheckpoint?.paused ?? false,
      restoredAt: restoredCheckpoint?.savedAt,
      active: !_progress.finished,
    );

    _completion = SessionCompletionService(
      checkpointStorage: resolvedCheckpointStorage,
      historyStorage: historyStorage ?? TrainingHistoryStorage(),
    );
    _notifications = SessionNotificationCoordinator(
      settingsStorage: settingsStorage ?? AppSettingsStorage(),
      stepEndNotifier: notificationService ?? StepEndNotificationService(),
      notificationSound: notificationSound ?? NotificationSound.classic,
      foregroundService:
          foregroundNotificationService ?? SessionNotificationService(),
      snapshotProvider: _notificationSnapshot,
      onPausePressed: togglePause,
      onTimedStepEnded: _handleTaskStepEnded,
      onModeChanged: _notifyIfActive,
    );

    if (_progress.finished) return;

    _notifications.start();
    unawaited(_enableWakelock());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    unawaited(_saveCheckpoint());
  }

  final Training training;
  final TrainingStorage _trainingStorage;
  final Future<void> Function() _enableWakelock;
  final Future<void> Function() _disableWakelock;

  late final SessionProgressState _progress;
  late final SessionClock _clock;
  late final SessionCompletionService _completion;
  late final SessionNotificationCoordinator _notifications;

  Timer? _ticker;
  bool _finishing = false;
  bool _disposed = false;

  List<SessionStep> get steps => _progress.steps;
  List<bool> get completed => _progress.completed;
  int get currentIndex => _progress.currentIndex;
  bool get paused => _clock.paused;
  bool get finished => _progress.finished;
  NotificationMode get notificationMode => _notifications.mode;
  bool get pendingIncompleteReview => _progress.pendingIncompleteReview;
  SessionStep get currentStep => _progress.currentStep;
  SessionStep? get nextStep => _progress.nextStep;
  Duration get globalElapsed => _clock.globalElapsed;
  Duration get stepElapsed => _clock.stepElapsed;

  SessionNotificationSnapshot _notificationSnapshot() =>
      SessionNotificationSnapshot(
        currentStep: steps.isEmpty ? null : currentStep,
        nextStep: steps.isEmpty ? null : nextStep,
        currentIndex: currentIndex,
        stepOccurrence: _progress.stepOccurrence,
        stepElapsed: stepElapsed,
        paused: paused,
        finished: finished,
        isAppBackgrounded: _clock.isAppBackgrounded,
      );

  void cycleNotificationMode() => _notifications.cycleMode();

  void handleAppBackgrounded() {
    if (finished) return;
    _clock.handleAppBackgrounded();
    _notifications.handleAppBackgrounded();
    unawaited(_saveCheckpoint());
  }

  void handleAppResumed() {
    if (finished || !_clock.handleAppResumed()) return;
    _notifications.handleAppResumed();
    _notifyIfActive();
    unawaited(_saveCheckpoint());
  }

  void _handleTaskStepEnded() {
    if (finished || paused) return;
    _clock.captureBackgroundStepEnd();
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
    _progress.recordCurrentStepDuration(stepElapsed);
    final completion = _progress.completeCurrentStep();

    switch (completion) {
      case SessionStepCompletion.advanced:
        _clock.resetStep();
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

    if (earlyExit) {
      unawaited(_notifications.stop(cancelSound: true));
    }

    _progress.recordCurrentStepDuration(stepElapsed);
    _ticker?.cancel();
    _clock.stop();

    try {
      await _disableWakelock();
      final status = _progress.allCompleted
          ? TrainingSessionStatus.completed
          : TrainingSessionStatus.incomplete;
      await _completion.completeSession(
        training: training,
        steps: steps,
        completed: completed,
        stepActualDurations: _progress.stepActualDurations,
        totalDuration: globalElapsed,
        status: status,
      );
      await _notifications.stop();
      _progress.markFinished();
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
    _clock.setPaused(paused);
    _notifications.handlePauseChanged();
    _notifyIfActive();
  }

  void jumpToStep(int index) {
    if (!_progress.canJumpTo(index) || finished || _finishing) return;

    _notifications.prepareManualStepChange();
    _progress.recordCurrentStepDuration(stepElapsed);
    final resumeAfterJump = pendingIncompleteReview && paused;
    _progress.jumpTo(index);
    _clock.resetStep();

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

  Future<void> updateComment(String? comment) async {
    currentStep.item.comment = comment;
    _notifyIfActive();
    await _trainingStorage.addOrUpdateTraining(training);
  }

  Future<void> abandon() {
    unawaited(_notifications.stop(cancelSound: true));
    return _completion.clearCheckpoint();
  }

  Future<void> _saveCheckpoint() {
    if (finished || _finishing) return Future<void>.value();
    return _completion.saveCheckpoint(
      trainingId: training.id,
      currentIndex: currentIndex,
      completed: completed,
      globalElapsed: globalElapsed,
      stepElapsed: stepElapsed,
      paused: paused,
      stepActualDurations: _progress.stepActualDurations,
    );
  }

  void _notifyIfActive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _ticker?.cancel();
    _clock.stop();
    unawaited(_disableWakelock());
    _notifications.dispose();
    super.dispose();
  }
}
