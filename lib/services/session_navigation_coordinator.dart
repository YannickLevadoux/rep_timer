import 'dart:async';

import 'session_clock.dart';
import 'session_notification_bridge.dart';
import 'session_progress_state.dart';
import 'session_timed_group_state.dart';

/// Applique les conséquences métier d'un changement manuel d'étape.
class SessionNavigationCoordinator {
  const SessionNavigationCoordinator({
    required this.progress,
    required this.clock,
    required this.timedGroups,
    required this.notifications,
    required this.onResume,
    required this.onChanged,
    required this.saveCheckpoint,
  });

  final SessionProgressState progress;
  final SessionClock clock;
  final SessionTimedGroupState timedGroups;
  final SessionNotificationBridge notifications;
  final void Function() onResume;
  final void Function() onChanged;
  final Future<void> Function() saveCheckpoint;

  bool jumpTo(int index, {required bool restartAmrap}) {
    if (!progress.canJumpTo(index) ||
        (timedGroups.requiresRestart(index) && !restartAmrap)) {
      return false;
    }
    notifications.prepareManualStepChange();
    timedGroups.leaveCurrent(
      index: progress.currentIndex,
      stepElapsed: clock.stepElapsed,
    );
    progress.recordCurrentStepDuration(clock.stepElapsed);
    final resume = progress.pendingIncompleteReview && clock.paused;
    progress.jumpTo(index);
    if (restartAmrap) timedGroups.restart(index);
    clock.resetStep();
    if (resume) {
      onResume();
    } else {
      notifications.handleManualStepChanged();
    }
    onChanged();
    unawaited(saveCheckpoint());
    return true;
  }
}
