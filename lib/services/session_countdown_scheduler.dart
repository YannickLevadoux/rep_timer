import 'dart:async';

import '../models/notification_mode.dart';
import '../models/notification_sound.dart';
import 'session_notification_snapshot.dart';
import 'step_end_notification_service.dart';

typedef SessionCountdownCancel = void Function();
typedef SessionCountdownSchedule =
    SessionCountdownCancel Function(Duration delay, void Function() callback);

/// Programme le compte à rebours et déduplique les effets de fin d'étape.
class SessionCountdownScheduler {
  factory SessionCountdownScheduler({
    required NotificationMode Function() modeProvider,
    required SessionNotificationSnapshot Function() snapshotProvider,
    required String Function(SessionNotificationSnapshot) stepTokenProvider,
    required StepEndNotifier stepEndNotifier,
    required NotificationSound notificationSound,
    required void Function() onTimedStepEnded,
    SessionCountdownSchedule? schedule,
  }) => SessionCountdownScheduler._(
    modeProvider,
    snapshotProvider,
    stepTokenProvider,
    stepEndNotifier,
    notificationSound,
    onTimedStepEnded,
    schedule ?? _scheduleTimer,
  );

  SessionCountdownScheduler._(
    this._modeProvider,
    this._snapshotProvider,
    this._stepTokenProvider,
    this._stepEndNotifier,
    this._notificationSound,
    this._onTimedStepEnded,
    this._schedule,
  );

  final NotificationMode Function() _modeProvider;
  final SessionNotificationSnapshot Function() _snapshotProvider;
  final String Function(SessionNotificationSnapshot) _stepTokenProvider;
  final StepEndNotifier _stepEndNotifier;
  final NotificationSound _notificationSound;
  final void Function() _onTimedStepEnded;
  final SessionCountdownSchedule _schedule;
  final Set<String> _soundNotificationsSent = <String>{};
  final Set<String> _vibrationNotificationsSent = <String>{};
  final Set<String> _stepEndsHandled = <String>{};

  SessionCountdownCancel? _cancelScheduled;
  bool _disposed = false;

  void preload() => unawaited(_stepEndNotifier.preload(_notificationSound));

  void arm() {
    suspend();
    final snapshot = _snapshotProvider();
    if (_modeProvider() != NotificationMode.sound ||
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

    final stepToken = _stepTokenProvider(snapshot);
    _cancelScheduled = _schedule(delay, () {
      _cancelScheduled = null;
      _playCountdownOnce(stepToken);
    });
  }

  void suspend() {
    _cancelScheduled?.call();
    _cancelScheduled = null;
  }

  void cancel() {
    suspend();
    unawaited(_stepEndNotifier.stopCountdown());
  }

  void handleSoundThreshold(String stepToken) {
    suspend();
    _playCountdownOnce(stepToken);
  }

  void handleTimedStepEnded(String stepToken, NotificationMode _) {
    final snapshot = _snapshotProvider();
    if (_disposed ||
        snapshot.finished ||
        snapshot.paused ||
        stepToken != _stepTokenProvider(snapshot) ||
        !_stepEndsHandled.add(stepToken)) {
      return;
    }
    _vibrateOnce(stepToken);
    _onTimedStepEnded();
  }

  void notifyTimedStepCompletionFallback() {
    final snapshot = _snapshotProvider();
    if (snapshot.currentStep?.item.duration != null) {
      _vibrateOnce(_stepTokenProvider(snapshot));
    }
  }

  void _playCountdownOnce(String stepToken) {
    final snapshot = _snapshotProvider();
    if (_disposed ||
        stepToken != _stepTokenProvider(snapshot) ||
        _modeProvider() != NotificationMode.sound ||
        !_soundNotificationsSent.add(stepToken)) {
      return;
    }
    unawaited(_stepEndNotifier.playCountdown(_notificationSound));
  }

  void _vibrateOnce(String stepToken) {
    final snapshot = _snapshotProvider();
    if (_disposed ||
        stepToken != _stepTokenProvider(snapshot) ||
        _modeProvider() != NotificationMode.vibration ||
        !_vibrationNotificationsSent.add(stepToken)) {
      return;
    }
    unawaited(_stepEndNotifier.vibrate());
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    suspend();
    _stepEndNotifier.dispose();
  }

  static SessionCountdownCancel _scheduleTimer(
    Duration delay,
    void Function() callback,
  ) {
    final timer = Timer(delay, callback);
    return timer.cancel;
  }
}
