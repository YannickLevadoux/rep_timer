import 'dart:async';

import '../models/notification_mode.dart';
import '../models/notification_sound.dart';
import 'app_settings_storage.dart';
import 'pre_session_signal_coordinator.dart';
import 'session_countdown_scheduler.dart';
import 'session_notification_data_builder.dart';
import 'session_notification_service.dart';
import 'session_notification_snapshot.dart';
import 'step_end_notification_service.dart';

export 'session_notification_snapshot.dart';

/// Orchestre réglages, état de séance, effets locaux et service Android.
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
    SessionCountdownSchedule? schedule,
  }) {
    final clock = now ?? DateTime.now;
    return SessionNotificationCoordinator._(
      settingsStorage,
      stepEndNotifier,
      notificationSound,
      foregroundService,
      snapshotProvider,
      onPausePressed,
      onTimedStepEnded,
      onModeChanged,
      clock,
      schedule,
    );
  }

  SessionNotificationCoordinator._(
    this._settingsStorage,
    StepEndNotifier stepEndNotifier,
    NotificationSound notificationSound,
    this._foregroundService,
    this._snapshotProvider,
    this._onPausePressed,
    void Function() onTimedStepEnded,
    this._onModeChanged,
    DateTime Function() now,
    SessionCountdownSchedule? schedule,
  ) : _dataBuilder = SessionNotificationDataBuilder(
        sessionToken: now().microsecondsSinceEpoch.toString(),
        soundGoOffset: notificationSound.goOffset,
        now: now,
      ) {
    _preparationSignals = PreSessionSignalCoordinator(
      modeProvider: () => _mode,
      notifier: stepEndNotifier,
      sound: notificationSound,
    );
    _countdown = SessionCountdownScheduler(
      modeProvider: () => _mode,
      snapshotProvider: _snapshotProvider,
      stepTokenProvider: _dataBuilder.stepToken,
      stepEndNotifier: stepEndNotifier,
      notificationSound: notificationSound,
      onTimedStepEnded: onTimedStepEnded,
      schedule: schedule,
    );
  }

  final AppSettingsStorage _settingsStorage;
  final SessionNotificationService _foregroundService;
  final SessionNotificationSnapshot Function() _snapshotProvider;
  final void Function() _onPausePressed;
  final void Function() _onModeChanged;
  final SessionNotificationDataBuilder _dataBuilder;
  late final SessionCountdownScheduler _countdown;
  late final PreSessionSignalCoordinator _preparationSignals;

  NotificationMode _mode = NotificationMode.none;
  bool _modeOverridden = false;
  bool _disposed = false;
  bool _sessionStarted = false;
  Future<void>? _stopFuture;
  Future<void>? _modeLoadFuture;

  NotificationMode get mode => _mode;

  void start() {
    _sessionStarted = true;
    if (_modeLoadFuture == null) prepare();
    _countdown.arm();
    syncForegroundNotification();
  }

  void prepare() {
    _countdown.preload();
    _modeLoadFuture ??= _loadInitialMode();
  }

  Future<void> _loadInitialMode() async {
    final mode = await _settingsStorage.loadNotificationMode();
    if (_disposed || _modeOverridden) return;
    _mode = mode;
    _preparationSignals.markModeReady();
    if (_sessionStarted) {
      _countdown.arm();
      syncForegroundNotification();
    }
    _onModeChanged();
  }

  void cycleMode() {
    _modeOverridden = true;
    _mode = _mode.next;
    _preparationSignals.discardPending();
    _countdown.cancel();
    if (_sessionStarted) {
      _countdown.arm();
      syncForegroundNotification();
    }
    _onModeChanged();
  }

  void signalPreparation(int secondsRemaining) =>
      _preparationSignals.emit(secondsRemaining);

  void stopPreparationSignal() => _preparationSignals.stop();

  void handleAppBackgrounded() => _countdown.suspend();

  void handleAppResumed() {
    _countdown.arm();
    syncForegroundNotification();
  }

  void handlePauseChanged() {
    if (_snapshotProvider().paused) {
      _countdown.cancel();
    } else {
      _countdown.arm();
    }
    syncForegroundNotification();
  }

  void handleNaturalStepAdvanced() {
    _countdown.arm();
    syncForegroundNotification();
  }

  void prepareManualStepChange() => _countdown.cancel();

  void handleManualStepChanged() {
    _countdown.arm();
    syncForegroundNotification();
  }

  void notifyTimedStepCompletionFallback() =>
      _countdown.notifyTimedStepCompletionFallback();

  void syncForegroundNotification() {
    if (_disposed) return;
    final snapshot = _snapshotProvider();
    final item = snapshot.currentStep?.item;
    if (snapshot.finished || item == null) return;
    if (item.duration == null && !item.isFreeDuration) {
      unawaited(_foregroundService.stop());
      return;
    }

    unawaited(
      _foregroundService.pin(
        data: _dataBuilder.build(snapshot: snapshot, mode: _mode),
        onPausePressed: _onPausePressed,
        onSoundThreshold: _countdown.handleSoundThreshold,
        onTimedStepEnded: _countdown.handleTimedStepEnded,
      ),
    );
  }

  Future<void> stop({bool cancelSound = false}) {
    if (cancelSound) _countdown.cancel();
    return _stopFuture ??= _foregroundService.stop();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _countdown.dispose();
    unawaited(stop());
    _foregroundService.dispose();
  }
}
