import 'package:flutter/material.dart';

import '../models/notification_mode.dart';
import '../models/session_step.dart';
import '../models/training_item.dart';
import 'section_divider.dart';
import 'session_command_row.dart';
import 'session_current_step_section.dart';
import 'session_progress_bar.dart';

/// Assemble les différentes sections de l'écran d'exécution d'une séance.
///
/// Toute la logique de séance reste dans le contrôleur et l'écran parent : ce
/// widget ne fait qu'organiser l'état reçu et transmettre les actions.
class SessionRunningBody extends StatelessWidget {
  final SessionStep step;
  final SessionStep? nextStep;
  final int currentIndex;
  final int totalSteps;
  final Duration globalElapsed;
  final Duration stepElapsed;
  final bool paused;
  final NotificationMode notificationMode;
  final Animation<double> blinkOpacity;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onComplete;
  final VoidCallback onTogglePause;
  final VoidCallback onEditComment;
  final VoidCallback onCycleNotificationMode;

  const SessionRunningBody({
    super.key,
    required this.step,
    required this.nextStep,
    required this.currentIndex,
    required this.totalSteps,
    required this.globalElapsed,
    required this.stepElapsed,
    required this.paused,
    required this.notificationMode,
    required this.blinkOpacity,
    required this.onPrevious,
    required this.onNext,
    required this.onComplete,
    required this.onTogglePause,
    required this.onEditComment,
    required this.onCycleNotificationMode,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          SessionCommandRow(
            globalElapsed: globalElapsed,
            paused: paused,
            notificationMode: notificationMode,
            previousEnabled: currentIndex > 0,
            nextEnabled: currentIndex < totalSteps - 1,
            onPrevious: onPrevious,
            onNext: onNext,
            onTogglePause: onTogglePause,
            onCycleNotificationMode: onCycleNotificationMode,
          ),
          const SizedBox(height: 4),
          SessionProgressBar(
            currentIndex: currentIndex,
            totalSteps: totalSteps,
          ),
          const SectionDivider(label: 'Prochain'),
          Text(
            _nextStepLabel(nextStep),
            key: const Key('next-step-label'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SectionDivider(label: 'En cours'),
          SessionCurrentStepSection(
            step: step,
            stepElapsed: stepElapsed,
            paused: paused,
            blinkOpacity: blinkOpacity,
            onComplete: onComplete,
            onEditComment: onEditComment,
          ),
        ],
      ),
    );
  }

  String _nextStepLabel(SessionStep? nextStep) {
    if (nextStep == null) return 'Fin de la séance';
    final itemLabel = nextStep.item.type == ItemType.rest
        ? 'Pause'
        : nextStep.item.name;
    return '${nextStep.group.name} — $itemLabel';
  }
}
