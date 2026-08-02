import 'dart:async';

import '../models/notification_mode.dart';
import 'session_notification_protocol.dart';

typedef CancelScheduledTrigger = void Function();
typedef ScheduleTrigger =
    CancelScheduledTrigger Function(Duration delay, void Function() callback);

/// Programme les seuils sonores et les fins d'étape sans dépendre d'un plugin.
///
/// Les tokens d'étape servent de clés d'idempotence : les resynchronisations
/// (pause, reprise ou retour au premier plan) peuvent réarmer les timers, mais
/// un événement déjà émis ne le sera jamais une seconde fois.
class StepEndTriggerScheduler {
  factory StepEndTriggerScheduler({
    required void Function(SessionNotificationEvent event) onEvent,
    DateTime Function()? now,
    ScheduleTrigger? schedule,
  }) => StepEndTriggerScheduler._(
    onEvent,
    now ?? DateTime.now,
    schedule ?? _scheduleTimer,
  );

  StepEndTriggerScheduler._(this._onEvent, this._now, this._schedule);

  final void Function(SessionNotificationEvent event) _onEvent;
  final DateTime Function() _now;
  final ScheduleTrigger _schedule;

  final Set<String> _soundThresholdsSent = <String>{};
  final Set<String> _soundThresholdsArmed = <String>{};
  final Set<String> _stepEndsSent = <String>{};

  SessionNotificationPinData? _state;
  CancelScheduledTrigger? _cancelSoundTrigger;
  CancelScheduledTrigger? _cancelStepEndTrigger;

  bool get hasState => _state != null;

  int get currentMilliseconds {
    final state = _state;
    if (state == null) return 0;
    if (!state.isPlaying) return state.baseMilliseconds;

    final elapsed = _now().millisecondsSinceEpoch - state.pinEpochMillis;
    final current = state.isCountingDown
        ? state.baseMilliseconds - elapsed
        : state.baseMilliseconds + elapsed;
    return state.isCountingDown && current < 0 ? 0 : current;
  }

  void update(SessionNotificationPinData state) {
    _cancelScheduledTriggers();
    _state = state;

    if (state.notificationMode != NotificationMode.sound) {
      _soundThresholdsArmed.remove(state.stepToken);
    }
    if (!state.isPlaying || !state.isCountingDown || state.stepToken.isEmpty) {
      return;
    }

    final remaining = currentMilliseconds;
    if (state.notificationMode == NotificationMode.sound &&
        !_soundThresholdsSent.contains(state.stepToken)) {
      final delay = remaining - state.soundGoOffsetMilliseconds;
      if (delay >= 0) {
        final token = state.stepToken;
        _soundThresholdsArmed.add(token);
        _cancelSoundTrigger = _schedule(
          Duration(milliseconds: delay),
          () => _emitSoundThreshold(token),
        );
      }
    }

    if (!_stepEndsSent.contains(state.stepToken)) {
      final token = state.stepToken;
      _cancelStepEndTrigger = _schedule(
        Duration(milliseconds: remaining),
        () => _emitStepEnd(token),
      );
    }
  }

  /// Filet de sécurité appelé à chaque rafraîchissement du service Android.
  /// Les protections d'idempotence rendent son usage sûr en parallèle des
  /// timers précis.
  void evaluate() {
    final state = _state;
    if (state == null ||
        !state.isPlaying ||
        !state.isCountingDown ||
        state.stepToken.isEmpty) {
      return;
    }

    final remaining = currentMilliseconds;
    if (state.notificationMode == NotificationMode.sound &&
        _soundThresholdsArmed.contains(state.stepToken) &&
        remaining <= state.soundGoOffsetMilliseconds) {
      _emitSoundThreshold(state.stepToken);
    }
    if (remaining <= 0) _emitStepEnd(state.stepToken);
  }

  void _emitSoundThreshold(String stepToken) {
    final state = _state;
    if (state == null ||
        !state.isPlaying ||
        state.notificationMode != NotificationMode.sound ||
        state.stepToken != stepToken ||
        !_soundThresholdsArmed.contains(stepToken) ||
        !_soundThresholdsSent.add(stepToken)) {
      return;
    }

    _cancelSoundTrigger = null;
    _onEvent(SessionSoundThresholdReached(stepToken));
  }

  void _emitStepEnd(String stepToken) {
    final state = _state;
    if (state == null ||
        !state.isPlaying ||
        state.stepToken != stepToken ||
        !_stepEndsSent.add(stepToken)) {
      return;
    }

    _cancelStepEndTrigger = null;
    _onEvent(SessionTimedStepEnded(stepToken, state.notificationMode));
  }

  void _cancelScheduledTriggers() {
    _cancelSoundTrigger?.call();
    _cancelStepEndTrigger?.call();
    _cancelSoundTrigger = null;
    _cancelStepEndTrigger = null;
  }

  void dispose() => _cancelScheduledTriggers();
}

CancelScheduledTrigger _scheduleTimer(
  Duration delay,
  void Function() callback,
) {
  final timer = Timer(delay, callback);
  return timer.cancel;
}
