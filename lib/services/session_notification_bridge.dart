import '../models/notification_mode.dart';
import '../models/notification_sound.dart';
import 'app_settings_storage.dart';
import 'session_clock.dart';
import 'session_notification_coordinator.dart';
import 'session_notification_service.dart';
import 'session_progress_state.dart';
import 'step_end_notification_service.dart';

/// Adapte l'état de progression et l'horloge au contrat du coordinateur de
/// notifications, puis expose uniquement les commandes utiles à la séance.
class SessionNotificationBridge {
  SessionNotificationBridge({
    required SessionProgressState progress,
    required SessionClock clock,
    required AppSettingsStorage settingsStorage,
    required StepEndNotifier stepEndNotifier,
    required NotificationSound notificationSound,
    required SessionNotificationService foregroundService,
    required void Function() onPausePressed,
    required void Function() onTimedStepEnded,
    required void Function() onModeChanged,
  }) : _coordinator = SessionNotificationCoordinator(
         settingsStorage: settingsStorage,
         stepEndNotifier: stepEndNotifier,
         notificationSound: notificationSound,
         foregroundService: foregroundService,
         snapshotProvider: () => SessionNotificationSnapshot(
           currentStep: progress.steps.isEmpty ? null : progress.currentStep,
           nextStep: progress.steps.isEmpty ? null : progress.nextStep,
           currentIndex: progress.currentIndex,
           stepOccurrence: progress.stepOccurrence,
           stepElapsed: clock.stepElapsed,
           paused: clock.paused,
           finished: progress.finished,
           isAppBackgrounded: clock.isAppBackgrounded,
         ),
         onPausePressed: onPausePressed,
         onTimedStepEnded: onTimedStepEnded,
         onModeChanged: onModeChanged,
       );

  final SessionNotificationCoordinator _coordinator;

  NotificationMode get mode => _coordinator.mode;

  void start() => _coordinator.start();
  void cycleMode() => _coordinator.cycleMode();
  void handleAppBackgrounded() => _coordinator.handleAppBackgrounded();
  void handleAppResumed() => _coordinator.handleAppResumed();
  void handlePauseChanged() => _coordinator.handlePauseChanged();
  void handleNaturalStepAdvanced() => _coordinator.handleNaturalStepAdvanced();
  void prepareManualStepChange() => _coordinator.prepareManualStepChange();
  void handleManualStepChanged() => _coordinator.handleManualStepChanged();
  void notifyTimedStepCompletionFallback() =>
      _coordinator.notifyTimedStepCompletionFallback();
  Future<void> stop({bool cancelSound = false}) =>
      _coordinator.stop(cancelSound: cancelSound);
  void dispose() => _coordinator.dispose();
}
