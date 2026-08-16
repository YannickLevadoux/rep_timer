import 'dart:async';

import 'package:flutter/foundation.dart';

import 'session_controller_composition.dart';
import 'session_notification_bridge.dart';
import 'session_preparation_controller.dart';

typedef SessionTickCancel = void Function();
typedef SessionTickSchedule = SessionTickCancel Function(void Function());

/// Cycle de vie commun des états préparation et exécution.
abstract class SessionControllerRuntime extends ChangeNotifier {
  SessionControllerRuntime({
    required SessionControllerComposition composition,
    this.trainingChangesPersistence = TrainingChangesPersistence.persistent,
    SessionTickSchedule? tickSchedule,
  }) : composition = composition {
    notifications = composition.createNotificationBridge(
      onPausePressed: togglePause,
      onTimedStepEnded: handleTimedStepEnded,
      onModeChanged: notifyIfActive,
    );
    preparation = SessionPreparationController(
      seconds: composition.preparationSeconds,
      now: composition.now,
      onSignal: notifications.signalPreparation,
      onChanged: notifyIfActive,
      onCompleted: _startPreparedSession,
    );
    if (composition.progress.finished) return;
    unawaited(composition.enableWakelock());
    _cancelTicker = (tickSchedule ?? _scheduleTicker)(_onTick);
    if (preparation.preparing) {
      notifications.prepare();
      preparation.start();
    } else {
      _startSessionEffects();
    }
  }

  final SessionControllerComposition composition;
  final TrainingChangesPersistence trainingChangesPersistence;
  late final SessionNotificationBridge notifications;
  late final SessionPreparationController preparation;
  SessionTickCancel? _cancelTicker;
  bool _disposed = false;

  Training get training => composition.training;

  void handleAppBackgrounded() {
    if (composition.progress.finished) return;
    if (preparation.preparing) {
      preparation.pause();
      notifications.stopPreparationSignal();
      return;
    }
    composition.clock.handleAppBackgrounded();
    notifications.handleAppBackgrounded();
    unawaited(saveCheckpoint());
  }

  void handleAppResumed() {
    if (preparation.preparing ||
        composition.progress.finished ||
        !composition.clock.handleAppResumed()) {
      return;
    }
    notifications.handleAppResumed();
    notifyIfActive();
    unawaited(saveCheckpoint());
  }

  void togglePause() {
    if (preparation.preparing) {
      preparation.togglePause();
      if (preparation.paused) notifications.stopPreparationSignal();
      return;
    }
    setPaused(!composition.clock.paused);
    unawaited(saveCheckpoint());
  }

  @protected
  void setPaused(bool paused) {
    composition.clock.setPaused(paused);
    notifications.handlePauseChanged();
    notifyIfActive();
  }

  @protected
  Future<void> saveCheckpoint() {
    if (preparation.preparing || !canSaveCheckpoint) return Future.value();
    return composition.saveCheckpoint();
  }

  @protected
  bool get canSaveCheckpoint;

  @protected
  void handleTimedStepEnded();

  @protected
  void handleRunningTick();

  @protected
  void stopTicker() {
    _cancelTicker?.call();
    _cancelTicker = null;
  }

  @protected
  void notifyIfActive() {
    if (!_disposed) notifyListeners();
  }

  void _onTick() {
    if (preparation.preparing) {
      preparation.tick();
    } else {
      handleRunningTick();
    }
  }

  void _startPreparedSession() {
    composition.clock.setPaused(false);
    _startSessionEffects();
  }

  void _startSessionEffects() {
    notifications.start();
    unawaited(saveCheckpoint());
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stopTicker();
    notifications.stopPreparationSignal();
    composition.clock.stop();
    unawaited(composition.disableWakelock());
    notifications.dispose();
    super.dispose();
  }
}

SessionTickCancel _scheduleTicker(void Function() callback) {
  final timer = Timer.periodic(const Duration(seconds: 1), (_) => callback());
  return timer.cancel;
}
