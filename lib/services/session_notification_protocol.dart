import '../models/notification_mode.dart';

/// Action envoyée par la notification Android vers l'isolate principal.
enum SessionNotificationAction {
  pause;

  static SessionNotificationAction? fromWire(Object? value) {
    if (value is! String) return null;
    for (final action in values) {
      if (action.name == value) return action;
    }
    return null;
  }
}

/// Point de référence transmis au service Android pour afficher le chrono et
/// programmer les événements de fin d'étape.
class SessionNotificationPinData {
  const SessionNotificationPinData({
    required this.stepLabel,
    required this.nextStepLabel,
    required this.stepToken,
    required this.notificationMode,
    required this.isPlaying,
    required this.isCountingDown,
    required this.baseMilliseconds,
    required this.pinEpochMillis,
    required this.soundGoOffsetMilliseconds,
  });

  final String stepLabel;
  final String nextStepLabel;
  final String stepToken;
  final NotificationMode notificationMode;
  final bool isPlaying;
  final bool isCountingDown;
  final int baseMilliseconds;
  final int pinEpochMillis;
  final int soundGoOffsetMilliseconds;

  Map<String, Object> toWire() => <String, Object>{
    'stepLabel': stepLabel,
    'nextStepLabel': nextStepLabel,
    'stepToken': stepToken,
    'notificationMode': notificationMode.name,
    'isPlaying': isPlaying,
    'isCountingDown': isCountingDown,
    'baseMilliseconds': baseMilliseconds,
    'pinEpochMillis': pinEpochMillis,
    'soundGoOffsetMilliseconds': soundGoOffsetMilliseconds,
  };

  static SessionNotificationPinData? fromWire(Object? value) {
    if (value is! Map) return null;

    final stepLabel = value['stepLabel'];
    final nextStepLabel = value['nextStepLabel'];
    final stepToken = value['stepToken'];
    final notificationMode = value['notificationMode'];
    final isPlaying = value['isPlaying'];
    final isCountingDown = value['isCountingDown'];
    final baseMilliseconds = value['baseMilliseconds'];
    final pinEpochMillis = value['pinEpochMillis'];
    final soundGoOffsetMilliseconds = value['soundGoOffsetMilliseconds'];

    if (stepLabel is! String ||
        nextStepLabel is! String ||
        stepToken is! String ||
        notificationMode is! String ||
        isPlaying is! bool ||
        isCountingDown is! bool ||
        baseMilliseconds is! int ||
        pinEpochMillis is! int ||
        soundGoOffsetMilliseconds is! int) {
      return null;
    }

    return SessionNotificationPinData(
      stepLabel: stepLabel,
      nextStepLabel: nextStepLabel,
      stepToken: stepToken,
      notificationMode: NotificationMode.fromName(notificationMode),
      isPlaying: isPlaying,
      isCountingDown: isCountingDown,
      baseMilliseconds: baseMilliseconds,
      pinEpochMillis: pinEpochMillis,
      soundGoOffsetMilliseconds: soundGoOffsetMilliseconds,
    );
  }
}

/// Événement de seuil émis par le service Android vers l'isolate principal.
sealed class SessionNotificationEvent {
  const SessionNotificationEvent(this.stepToken);

  final String stepToken;

  Map<String, Object> toWire();

  static SessionNotificationEvent? fromWire(Object? value) {
    if (value is! Map) return null;
    final type = value['event'];
    final stepToken = value['stepToken'];
    if (type is! String || stepToken is! String) return null;

    return switch (type) {
      _soundThresholdEvent => SessionSoundThresholdReached(stepToken),
      _timedStepEndedEvent when value['notificationMode'] is String =>
        SessionTimedStepEnded(
          stepToken,
          NotificationMode.fromName(value['notificationMode'] as String),
        ),
      _ => null,
    };
  }
}

class SessionSoundThresholdReached extends SessionNotificationEvent {
  const SessionSoundThresholdReached(super.stepToken);

  @override
  Map<String, Object> toWire() => <String, Object>{
    'event': _soundThresholdEvent,
    'stepToken': stepToken,
  };
}

class SessionTimedStepEnded extends SessionNotificationEvent {
  const SessionTimedStepEnded(super.stepToken, this.notificationMode);

  final NotificationMode notificationMode;

  @override
  Map<String, Object> toWire() => <String, Object>{
    'event': _timedStepEndedEvent,
    'stepToken': stepToken,
    'notificationMode': notificationMode.name,
  };
}

const String _soundThresholdEvent = 'soundThreshold';
const String _timedStepEndedEvent = 'timedStepEnded';
