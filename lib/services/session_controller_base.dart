import 'dart:async';

import 'package:flutter/foundation.dart';

import 'session_controller_composition.dart';
import 'session_notification_bridge.dart';
import 'session_navigation_coordinator.dart';

typedef SessionTickCancel = void Function();
typedef SessionTickSchedule = SessionTickCancel Function(void Function());

/// Orchestration du cycle de vie, des horloges et des effets d'une séance.
abstract class SessionControllerBase extends ChangeNotifier {
  SessionControllerBase({
    required SessionControllerComposition composition,
    this.trainingChangesPersistence = TrainingChangesPersistence.persistent,
    SessionTickSchedule? tickSchedule,
  }) {
    _composition = composition;
    _notifications = _composition.createNotificationBridge(
      onPausePressed: togglePause,
      onTimedStepEnded: _handleTimedStepEnded,
      onModeChanged: notifyIfActive,
    );
    _navigation = SessionNavigationCoordinator(
      progress: _composition.progress,
      clock: _composition.clock,
      timedGroups: _composition.timedGroups,
      notifications: _notifications,
      onResume: () => _setPaused(false),
      onChanged: notifyIfActive,
      saveCheckpoint: saveCheckpoint,
    );
    if (_composition.progress.finished) return;
    _notifications.start();
    unawaited(_composition.enableWakelock());
    _cancelTicker = (tickSchedule ?? _scheduleTicker)(_onTick);
    unawaited(saveCheckpoint());
  }

  Training get training => _composition.training;
  final TrainingChangesPersistence trainingChangesPersistence;
  late final SessionControllerComposition _composition;
  late final SessionNotificationBridge _notifications;
  late final SessionNavigationCoordinator _navigation;
  SessionTickCancel? _cancelTicker;
  bool _finishing = false, _disposed = false;

  @protected
  SessionControllerComposition get composition => _composition;
  @protected
  SessionNotificationBridge get notifications => _notifications;
  void handleAppBackgrounded() {
    if (_composition.progress.finished) return;
    _composition.clock.handleAppBackgrounded();
    _notifications.handleAppBackgrounded();
    unawaited(saveCheckpoint());
  }

  void handleAppResumed() {
    if (_composition.progress.finished ||
        !_composition.clock.handleAppResumed()) {
      return;
    }
    _notifications.handleAppResumed();
    notifyIfActive();
    unawaited(saveCheckpoint());
  }

  void _handleTimedStepEnded() {
    if (_composition.progress.finished || _composition.clock.paused) return;
    _composition.clock.captureBackgroundStepEnd();
    completeCurrentStep();
  }

  void _onTick() {
    if (_composition.clock.paused ||
        _composition.progress.finished ||
        _finishing) {
      return;
    }
    final duration = _composition.progress.currentStep.item.duration;
    final elapsed = _composition.clock.stepElapsed;
    if (duration != null && elapsed >= duration) {
      completeCurrentStep();
    } else {
      _composition.amrapSnapshot;
      notifyIfActive();
    }
  }

  void completeCurrentStep() {
    if (_composition.progress.finished || _finishing) return;
    final amrap = _composition.amrapSnapshot;
    if (amrap != null && amrap.activeRemaining > Duration.zero) return;
    _composition.timedGroups.completeCurrent(
      index: _composition.progress.currentIndex,
      stepElapsed: _composition.clock.stepElapsed,
    );
    _notifications.notifyTimedStepCompletionFallback();
    _composition.progress.recordCurrentStepDuration(
      _composition.clock.stepElapsed,
    );
    switch (_composition.progress.completeCurrentStep()) {
      case SessionStepCompletion.advanced:
        _composition.clock.resetStep();
        _notifications.handleNaturalStepAdvanced();
        notifyIfActive();
        unawaited(saveCheckpoint());
      case SessionStepCompletion.sessionCompleted:
        unawaited(finishSession());
      case SessionStepCompletion.needsReview:
        _setPaused(true);
        unawaited(saveCheckpoint());
    }
  }

  Future<void> finishSession({bool earlyExit = false}) async {
    if (_composition.progress.finished || _finishing) return;
    _finishing = true;
    if (earlyExit) unawaited(_notifications.stop(cancelSound: true));
    _composition.progress.recordCurrentStepDuration(
      _composition.clock.stepElapsed,
    );
    _cancelTicker?.call();
    _composition.clock.stop();
    try {
      await _composition.disableWakelock();
      await _composition.completeSession();
      await _notifications.stop();
      _composition.progress.markFinished();
      notifyIfActive();
    } finally {
      if (!_composition.progress.finished) _finishing = false;
    }
  }

  void togglePause() {
    _setPaused(!_composition.clock.paused);
    unawaited(saveCheckpoint());
  }

  void _setPaused(bool paused) {
    _composition.clock.setPaused(paused);
    _notifications.handlePauseChanged();
    notifyIfActive();
  }

  bool jumpToStep(int index, {bool restartAmrap = false}) {
    if (!_composition.progress.canJumpTo(index) ||
        _composition.progress.finished ||
        _finishing) {
      return false;
    }
    return _navigation.jumpTo(index, restartAmrap: restartAmrap);
  }

  bool goToPrevious({bool restartAmrap = false}) => jumpToStep(
    _composition.progress.currentIndex - 1,
    restartAmrap: restartAmrap,
  );
  bool goToNext({bool restartAmrap = false}) => jumpToStep(
    _composition.progress.currentIndex + 1,
    restartAmrap: restartAmrap,
  );

  Future<void> abandon() {
    unawaited(_notifications.stop(cancelSound: true));
    return _composition.completion.clearCheckpoint();
  }

  @protected
  Future<void> saveCheckpoint() {
    if (_composition.progress.finished || _finishing) return Future.value();
    return _composition.saveCheckpoint();
  }

  @protected
  void notifyIfActive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelTicker?.call();
    _composition.clock.stop();
    unawaited(_composition.disableWakelock());
    _notifications.dispose();
    super.dispose();
  }
}

SessionTickCancel _scheduleTicker(void Function() callback) {
  final timer = Timer.periodic(const Duration(seconds: 1), (_) => callback());
  return timer.cancel;
}
