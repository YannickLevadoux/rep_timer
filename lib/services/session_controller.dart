import 'dart:async';

import 'amrap_execution_state.dart';
import 'session_clock.dart';
import 'session_controller_base.dart';
import 'session_controller_composition.dart';

export 'training_changes_persistence.dart';

/// Façade observable consommée par l'écran de séance.
class SessionController extends SessionControllerBase {
  SessionController({
    required Training training,
    super.trainingChangesPersistence = TrainingChangesPersistence.persistent,
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
    SessionNow? now,
    super.tickSchedule,
  }) : super(
         composition: SessionControllerComposition(
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
           now: now,
         ),
       );

  List<SessionStep> get steps => composition.progress.steps;
  List<bool> get completed => composition.progress.completed;
  int get currentIndex => composition.progress.currentIndex;
  bool get paused => composition.clock.paused;
  bool get finished => composition.progress.finished;
  NotificationMode get notificationMode => notifications.mode;
  bool get pendingIncompleteReview => composition.pendingIncompleteReview;
  SessionStep get currentStep => composition.progress.currentStep;
  SessionStep? get nextStep => composition.progress.nextStep;
  Duration get globalElapsed => composition.clock.globalElapsed;
  Duration get stepElapsed => composition.clock.stepElapsed;
  AmrapExecutionSnapshot? get amrap => composition.amrapSnapshot;

  void cycleNotificationMode() => notifications.cycleMode();
  bool requiresAmrapRestart(int index) =>
      composition.timedGroups.requiresRestart(index);

  bool recordAmrapLap() {
    final changed = composition.timedGroups.recordLap(
      index: currentIndex,
      stepElapsed: stepElapsed,
      paused: paused,
    );
    if (changed) _stateChangedAndSaved();
    return changed;
  }

  bool undoLastAmrapLap() {
    final changed = composition.timedGroups.undoLastLap(
      index: currentIndex,
      stepElapsed: stepElapsed,
    );
    if (changed) _stateChangedAndSaved();
    return changed;
  }

  Future<void> updateComment(String? comment) => composition.comments.update(
    comment: comment,
    currentStep: currentStep,
    steps: steps,
    training: training,
    persistence: trainingChangesPersistence,
    onChanged: notifyIfActive,
  );

  void _stateChangedAndSaved() {
    notifyIfActive();
    unawaited(saveCheckpoint());
  }
}
