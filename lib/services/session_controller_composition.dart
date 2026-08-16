import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/notification_sound.dart';
import '../models/session_checkpoint.dart';
import '../models/training.dart';
import '../models/training_history_entry.dart';
import 'app_settings_storage.dart';
import 'pre_session_countdown_storage.dart';
import 'amrap_execution_state.dart';
import 'session_checkpoint_storage.dart';
import 'session_clock.dart';
import 'session_comment_updater.dart';
import 'session_completion_service.dart';
import 'session_notification_bridge.dart';
import 'session_notification_service.dart';
import 'session_progress_state.dart';
import 'session_timed_group_state.dart';
import 'step_end_notification_service.dart';
import 'training_history_storage.dart';
import 'training_storage.dart';

export '../models/notification_mode.dart';
export '../models/notification_sound.dart';
export '../models/session_checkpoint.dart';
export '../models/session_step.dart';
export '../models/training.dart';
export 'app_settings_storage.dart';
export 'session_checkpoint_storage.dart';
export 'session_notification_service.dart';
export 'session_progress_state.dart';
export 'step_end_notification_service.dart';
export 'training_changes_persistence.dart';
export 'training_history_storage.dart';
export 'training_storage.dart';

/// Résout les dépendances et compose les services spécialisés d'une séance.
class SessionControllerComposition {
  factory SessionControllerComposition({
    required Training training,
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
    int preSessionCountdownSeconds = 0,
  }) {
    final progress = SessionProgressState(
      training: training,
      checkpoint: initialCheckpoint,
    );
    final restored = progress.restoredFromCheckpoint ? initialCheckpoint : null;
    final sessionNow = now ?? DateTime.now;
    final countdownSeconds = isValidCountdownSeconds(preSessionCountdownSeconds)
        ? preSessionCountdownSeconds
        : defaultCountdownSeconds;
    final shouldPrepare =
        initialCheckpoint == null && !progress.finished && countdownSeconds > 0;
    final clock = SessionClock(
      initialGlobalElapsed: restored?.globalElapsed ?? Duration.zero,
      initialStepElapsed: restored?.stepElapsed ?? Duration.zero,
      initiallyPaused: shouldPrepare || (restored?.paused ?? false),
      restoredAt: restored?.savedAt,
      active: !progress.finished,
      now: sessionNow,
    );
    final timedGroups = SessionTimedGroupState(
      steps: progress.steps,
      checkpoint: restored,
    );
    final checkpoints = checkpointStorage ?? SessionCheckpointStorage();
    return SessionControllerComposition._(
      training: training,
      progress: progress,
      clock: clock,
      timedGroups: timedGroups,
      completion: SessionCompletionService(
        checkpointStorage: checkpoints,
        historyStorage: historyStorage ?? TrainingHistoryStorage(),
        now: sessionNow,
      ),
      comments: SessionCommentUpdater(
        trainingStorage: trainingStorage ?? TrainingStorage(),
      ),
      settingsStorage: settingsStorage ?? AppSettingsStorage(),
      stepEndNotifier: notificationService ?? StepEndNotificationService(),
      notificationSound: notificationSound ?? NotificationSound.classic,
      foregroundService:
          foregroundNotificationService ?? SessionNotificationService(),
      enableWakelock: enableWakelock ?? WakelockPlus.enable,
      disableWakelock: disableWakelock ?? WakelockPlus.disable,
      now: sessionNow,
      preparationSeconds: shouldPrepare ? countdownSeconds : 0,
    );
  }

  const SessionControllerComposition._({
    required this.training,
    required this.progress,
    required this.clock,
    required this.timedGroups,
    required this.completion,
    required this.comments,
    required this._settingsStorage,
    required this._stepEndNotifier,
    required this._notificationSound,
    required this._foregroundService,
    required this.enableWakelock,
    required this.disableWakelock,
    required this.now,
    required this.preparationSeconds,
  });

  final Training training;
  final SessionProgressState progress;
  final SessionClock clock;
  final SessionTimedGroupState timedGroups;
  final SessionCompletionService completion;
  final SessionCommentUpdater comments;
  final AppSettingsStorage _settingsStorage;
  final StepEndNotifier _stepEndNotifier;
  final NotificationSound _notificationSound;
  final SessionNotificationService _foregroundService;
  final Future<void> Function() enableWakelock;
  final Future<void> Function() disableWakelock;
  final SessionNow now;
  final int preparationSeconds;

  bool get pendingIncompleteReview => progress.pendingIncompleteReview;
  AmrapExecutionSnapshot? get amrapSnapshot => timedGroups.snapshot(
    index: progress.currentIndex,
    stepElapsed: clock.stepElapsed,
    paused: clock.paused,
  );

  SessionNotificationBridge createNotificationBridge({
    required void Function() onPausePressed,
    required void Function() onTimedStepEnded,
    required void Function() onModeChanged,
  }) => SessionNotificationBridge(
    progress: progress,
    clock: clock,
    settingsStorage: _settingsStorage,
    stepEndNotifier: _stepEndNotifier,
    notificationSound: _notificationSound,
    foregroundService: _foregroundService,
    onPausePressed: onPausePressed,
    onTimedStepEnded: onTimedStepEnded,
    onModeChanged: onModeChanged,
  );

  Future<void> saveCheckpoint() => completion.saveCheckpoint(
    trainingId: training.id,
    currentIndex: progress.currentIndex,
    completed: progress.completed,
    globalElapsed: clock.globalElapsed,
    stepElapsed: clock.stepElapsed,
    paused: clock.paused,
    stepActualDurations: progress.stepActualDurations,
    amrapStates: timedGroups.checkpoints(
      index: progress.currentIndex,
      stepElapsed: clock.stepElapsed,
    ),
  );

  Future<void> completeSession() {
    timedGroups.snapshot(
      index: progress.currentIndex,
      stepElapsed: clock.stepElapsed,
      paused: clock.paused,
    );
    return completion.completeSession(
      training: training,
      steps: progress.steps,
      completed: progress.completed,
      stepActualDurations: progress.stepActualDurations,
      totalDuration: clock.globalElapsed,
      status: progress.allCompleted
          ? TrainingSessionStatus.completed
          : TrainingSessionStatus.incomplete,
      amrapHistory: timedGroups.historyData(progress.completed),
    );
  }
}
