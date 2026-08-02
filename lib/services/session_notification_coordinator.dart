import 'dart:async';

import '../models/notification_mode.dart';
import '../models/notification_sound.dart';
import '../models/session_step.dart';
import '../models/training_item.dart';
import 'app_settings_storage.dart';
import 'session_notification_protocol.dart';
import 'session_notification_service.dart';
import 'step_end_notification_service.dart';

class SessionNotificationSnapshot {
  const SessionNotificationSnapshot({
    required this.currentStep,
    required this.nextStep,
    required this.currentIndex,
    required this.stepOccurrence,
    required this.stepElapsed,
    required this.paused,
    required this.finished,
    required this.isAppBackgrounded,
  });

  final SessionStep? currentStep;
  final SessionStep? nextStep;
  final int currentIndex;
  final int stepOccurrence;
  final Duration stepElapsed;
  final bool paused;
  final bool finished;
  final bool isAppBackgrounded;
}

/// Coordonne le mode de notification d'une séance, le filet de sécurité
/// de l'isolate principal et le Foreground Service Android.
class SessionNotificationCoordinator {
  factory SessionNotificationCoordinator({
    required AppSettingsStorage settingsStorage,
    required StepEndNotifier stepEndNotifier,
    required NotificationSound notificationSound,
    required SessionNotificationService foregroundService,
    required SessionNotificationSnapshot Function() snapshotProvider,
    required void Function() onPausePressed,
    required void Function() onTimedStepEnded,
    required void Function() onModeChanged,
    DateTime Function()? now,
  }) => SessionNotificationCoordinator._(
    settingsStorage: settingsStorage,
    stepEndNotifier: stepEndNotifier,
    notificationSound: notificationSound,
    foregroundService: foregroundService,
    snapshotProvider: snapshotProvider,
    onPausePressed: onPausePressed,
    onTimedStepEnded: onTimedStepEnded,
    onModeChanged: onModeChanged,
    now: now ?? DateTime.now,
  );

  SessionNotificationCoordinator._({
    required this._settingsStorage,
    required this._stepEndNotifier,
    required this._notificationSound,
    required this._foregroundService,
    required this._snapshotProvider,
    required this._onPausePressed,
    required this._onTimedStepEnded,
    required this._onModeChanged,
    required DateTime Function() now,
  }) : _sessionToken = now().microsecondsSinceEpoch.toString();

  final AppSettingsStorage _settingsStorage;
  final StepEndNotifier _stepEndNotifier;
  final NotificationSound _notificationSound;
  final SessionNotificationService _foregroundService;
  final SessionNotificationSnapshot Function() _snapshotProvider;
  final void Function() _onPausePressed;
  final void Function() _onTimedStepEnded;
  final void Function() _onModeChanged;
  final String _sessionToken;

  final Set<String> _soundNotificationsSent = <String>{};
  final Set<String> _vibrationNotificationsSent = <String>{};
  Timer? _countdownTimer;
  NotificationMode _mode = NotificationMode.none;
  bool _modeOverridden = false;
  bool _disposed = false;

  NotificationMode get mode => _mode;

  void start() {
    unawaited(_stepEndNotifier.preload(_notificationSound));
    _armCountdown();
    syncForegroundNotification();
    unawaited(_loadInitialMode());
  }

  Future<void> _loadInitialMode() async {
    final mode = await _settingsStorage.loadNotificationMode();
    if (_disposed || _modeOverridden) return;

    _mode = mode;
    _armCountdown();
    syncForegroundNotification();
    _onModeChanged();
  }

  void cycleMode() {
    _modeOverridden = true;
    _mode = _mode.next;
    _cancelCountdown();
    _armCountdown();
    syncForegroundNotification();
    _onModeChanged();
  }

  void handleAppBackgrounded() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void handleAppResumed() {
    _armCountdown();
    syncForegroundNotification();
  }

  void handlePauseChanged() {
    if (_snapshotProvider().paused) {
      _cancelCountdown();
    } else {
      _armCountdown();
    }
    syncForegroundNotification();
  }

  void handleNaturalStepAdvanced() {
    _armCountdown();
    syncForegroundNotification();
  }

  void prepareManualStepChange() => _cancelCountdown();

  void handleManualStepChanged() {
    _armCountdown();
    syncForegroundNotification();
  }

  void notifyTimedStepCompletionFallback() {
    final snapshot = _snapshotProvider();
    final step = snapshot.currentStep;
    if (step?.item.duration != null) {
      _vibrateOnce(_stepToken(snapshot));
    }
  }

  void _armCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;

    final snapshot = _snapshotProvider();
    if (_mode != NotificationMode.sound ||
        snapshot.paused ||
        snapshot.finished ||
        snapshot.isAppBackgrounded) {
      return;
    }

    final duration = snapshot.currentStep?.item.duration;
    if (duration == null) return;

    final delay =
        (duration - snapshot.stepElapsed) - _notificationSound.goOffset;
    if (delay.isNegative) return;

    final stepToken = _stepToken(snapshot);
    _countdownTimer = Timer(delay, () {
      _countdownTimer = null;
      _playCountdownOnce(stepToken);
    });
  }

  void _playCountdownOnce(String stepToken) {
    final snapshot = _snapshotProvider();
    if (_disposed ||
        stepToken != _stepToken(snapshot) ||
        _mode != NotificationMode.sound ||
        !_soundNotificationsSent.add(stepToken)) {
      return;
    }
    unawaited(_stepEndNotifier.playCountdown(_notificationSound));
  }

  void _vibrateOnce(String stepToken) {
    final snapshot = _snapshotProvider();
    if (_disposed ||
        stepToken != _stepToken(snapshot) ||
        _mode != NotificationMode.vibration ||
        !_vibrationNotificationsSent.add(stepToken)) {
      return;
    }
    unawaited(_stepEndNotifier.vibrate());
  }

  void _handleTaskSoundThreshold(String stepToken) {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _playCountdownOnce(stepToken);
  }

  void _handleTaskStepEnded(String stepToken, NotificationMode _) {
    final snapshot = _snapshotProvider();
    if (_disposed ||
        snapshot.finished ||
        snapshot.paused ||
        stepToken != _stepToken(snapshot)) {
      return;
    }

    _vibrateOnce(stepToken);
    _onTimedStepEnded();
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    unawaited(_stepEndNotifier.stopCountdown());
  }

  void syncForegroundNotification() {
    if (_disposed) return;

    final snapshot = _snapshotProvider();
    final step = snapshot.currentStep;
    if (snapshot.finished || step == null) return;

    final item = step.item;
    final needsNotification = item.duration != null || item.isFreeDuration;
    if (!needsNotification) {
      unawaited(_foregroundService.stop());
      return;
    }

    final isCountingDown = item.duration != null;
    final currentDuration = isCountingDown
        ? (item.duration! - snapshot.stepElapsed)
        : snapshot.stepElapsed;
    final baseMilliseconds = currentDuration.isNegative
        ? 0
        : currentDuration.inMilliseconds;
    final stepLabel = item.type == ItemType.rest ? 'Pause' : item.name;

    unawaited(
      _foregroundService.pin(
        data: SessionNotificationPinData(
          stepLabel: stepLabel,
          nextStepLabel: _nextStepLabel(snapshot.nextStep),
          stepToken: _stepToken(snapshot),
          notificationMode: _mode,
          isPlaying: !snapshot.paused,
          isCountingDown: isCountingDown,
          baseMilliseconds: baseMilliseconds,
          pinEpochMillis: DateTime.now().millisecondsSinceEpoch,
          soundGoOffsetMilliseconds: _notificationSound.goOffset.inMilliseconds,
        ),
        onPausePressed: _onPausePressed,
        onSoundThreshold: _handleTaskSoundThreshold,
        onTimedStepEnded: _handleTaskStepEnded,
      ),
    );
  }

  String _nextStepLabel(SessionStep? nextStep) {
    if (nextStep == null) return 'Fin de la séance';
    final itemLabel = nextStep.item.type == ItemType.rest
        ? 'Pause'
        : nextStep.item.name;
    return 'Suivant : ${nextStep.group.name} - $itemLabel';
  }

  String _stepToken(SessionNotificationSnapshot snapshot) =>
      '$_sessionToken:${snapshot.currentIndex}:${snapshot.stepOccurrence}';

  Future<void> stop({bool cancelSound = false}) {
    if (cancelSound) _cancelCountdown();
    return _foregroundService.stop();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _countdownTimer?.cancel();
    _stepEndNotifier.dispose();
    unawaited(_foregroundService.stop());
    _foregroundService.dispose();
  }
}
