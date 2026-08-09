import '../models/notification_mode.dart';
import '../models/session_step.dart';
import '../models/training_item.dart';
import 'session_notification_protocol.dart';
import 'session_notification_snapshot.dart';

/// Construit les données immuables transmises au Foreground Service.
class SessionNotificationDataBuilder {
  const SessionNotificationDataBuilder({
    required this.sessionToken,
    required this.soundGoOffset,
    required this.now,
  });

  final String sessionToken;
  final Duration soundGoOffset;
  final DateTime Function() now;

  String stepToken(SessionNotificationSnapshot snapshot) =>
      '$sessionToken:${snapshot.currentIndex}:${snapshot.stepOccurrence}';

  SessionNotificationPinData build({
    required SessionNotificationSnapshot snapshot,
    required NotificationMode mode,
  }) {
    final item = snapshot.currentStep!.item;
    final isCountingDown = item.duration != null;
    final currentDuration = isCountingDown
        ? (item.duration! - snapshot.stepElapsed)
        : snapshot.stepElapsed;

    return SessionNotificationPinData(
      stepLabel: item.type == ItemType.rest ? 'Pause' : item.name,
      nextStepLabel: _nextStepLabel(snapshot.nextStep),
      stepToken: stepToken(snapshot),
      notificationMode: mode,
      isPlaying: !snapshot.paused,
      isCountingDown: isCountingDown,
      baseMilliseconds: currentDuration.isNegative
          ? 0
          : currentDuration.inMilliseconds,
      pinEpochMillis: now().millisecondsSinceEpoch,
      soundGoOffsetMilliseconds: soundGoOffset.inMilliseconds,
    );
  }

  String _nextStepLabel(SessionStep? nextStep) {
    if (nextStep == null) return 'Fin de la séance';
    final itemLabel = nextStep.item.type == ItemType.rest
        ? 'Pause'
        : nextStep.item.name;
    return 'Suivant : ${nextStep.group.name} - $itemLabel';
  }
}
