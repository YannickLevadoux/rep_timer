import '../models/session_step.dart';

/// État minimal d'une séance nécessaire à la coordination des notifications.
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
