import '../models/session_checkpoint.dart';
import '../models/session_step.dart';
import '../models/training.dart';
import '../models/group_type.dart';
import '../models/training_item.dart';

enum SessionStepCompletion { advanced, sessionCompleted, needsReview }

/// État pur de progression d'une séance, indépendant des horloges,
/// plugins et stockages.
class SessionProgressState {
  SessionProgressState({
    required Training training,
    SessionCheckpoint? checkpoint,
  }) : steps = buildSessionSteps(training) {
    restoredFromCheckpoint = _canRestore(checkpoint);
    if (restoredFromCheckpoint) {
      currentIndex = checkpoint!.currentIndex;
      completed = List<bool>.of(checkpoint.completed);
      stepActualDurations = List<Duration>.of(checkpoint.stepActualDurations);
      if (checkpoint.paused &&
          currentIndex == steps.length - 1 &&
          completed[currentIndex] &&
          !allCompleted) {
        pendingIncompleteReview = true;
      }
    } else {
      completed = List<bool>.filled(steps.length, false);
      stepActualDurations = List<Duration>.filled(steps.length, Duration.zero);
    }

    finished = steps.isEmpty;
  }

  final List<SessionStep> steps;
  late final bool restoredFromCheckpoint;
  late final List<bool> completed;
  late final List<Duration> stepActualDurations;

  int currentIndex = 0;
  int stepOccurrence = 0;
  bool pendingIncompleteReview = false;
  bool finished = false;

  bool get allCompleted => completed.every((value) => value);
  SessionStep get currentStep => steps[currentIndex];
  SessionStep? get nextStep =>
      currentIndex + 1 < steps.length ? steps[currentIndex + 1] : null;

  bool canJumpTo(int index) => index >= 0 && index < steps.length;

  void recordCurrentStepDuration(Duration duration) {
    if (!canJumpTo(currentIndex)) return;
    stepActualDurations[currentIndex] = duration;
  }

  SessionStepCompletion completeCurrentStep() {
    completed[currentIndex] = true;

    if (currentIndex + 1 < steps.length) {
      currentIndex++;
      stepOccurrence++;
      return SessionStepCompletion.advanced;
    }

    if (allCompleted) return SessionStepCompletion.sessionCompleted;

    pendingIncompleteReview = true;
    return SessionStepCompletion.needsReview;
  }

  bool jumpTo(int index) {
    if (!canJumpTo(index)) return false;
    if (_isEmomMinute(currentIndex)) completed[currentIndex] = false;
    currentIndex = index;
    if (_isEmomMinute(currentIndex)) completed[currentIndex] = false;
    stepOccurrence++;
    pendingIncompleteReview = false;
    return true;
  }

  void markFinished() {
    pendingIncompleteReview = false;
    finished = true;
  }

  bool _isEmomMinute(int index) =>
      steps[index].group.type == GroupType.emom &&
      steps[index].item.type == ItemType.exercise;

  bool _canRestore(SessionCheckpoint? checkpoint) =>
      checkpoint != null &&
      checkpoint.completed.length == steps.length &&
      checkpoint.stepActualDurations.length == steps.length &&
      checkpoint.currentIndex >= 0 &&
      checkpoint.currentIndex < steps.length;
}
