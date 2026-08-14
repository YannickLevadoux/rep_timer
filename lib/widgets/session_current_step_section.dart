import 'package:flutter/material.dart';

import '../models/session_step.dart';
import '../services/amrap_execution_state.dart';
import '../utils/formatters.dart';
import 'session_amrap_controls.dart';
import 'session_comment_section.dart';
import 'session_step_header.dart';
import 'session_step_validation.dart';

/// Affiche toutes les informations et actions propres à l'étape en cours.
class SessionCurrentStepSection extends StatelessWidget {
  const SessionCurrentStepSection({
    super.key,
    required this.step,
    required this.stepElapsed,
    required this.paused,
    required this.blinkOpacity,
    required this.onComplete,
    required this.onEditComment,
    this.amrap,
    this.onRecordAmrapLap,
    this.onUndoAmrapLap,
  });

  final SessionStep step;
  final Duration stepElapsed;
  final bool paused;
  final Animation<double> blinkOpacity;
  final VoidCallback onComplete;
  final VoidCallback onEditComment;
  final AmrapExecutionSnapshot? amrap;
  final VoidCallback? onRecordAmrapLap;
  final VoidCallback? onUndoAmrapLap;

  @override
  Widget build(BuildContext context) {
    final item = step.item;
    final remaining = item.duration == null
        ? null
        : item.duration! - stepElapsed;
    final standardTime = remaining?.isNegative == true
        ? Duration.zero
        : remaining ?? stepElapsed;
    return Column(
      children: [
        SessionStepMetadata(step: step),
        const SizedBox(height: 12),
        Text(
          formatDuration(amrap?.activeRemaining ?? standardTime),
          key: const Key('step-timer'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SessionStepIdentity(item: item, blinkOpacity: blinkOpacity),
        const SizedBox(height: 4),
        SessionCommentSection(
          item: item,
          blinkOpacity: blinkOpacity,
          onEditComment: onEditComment,
        ),
        if (amrap != null)
          SessionAmrapControls(
            state: amrap!,
            onRecordLap: onRecordAmrapLap!,
            onUndoLastLap: onUndoAmrapLap!,
          )
        else
          SessionStepValidation(
            item: item,
            paused: paused,
            onComplete: onComplete,
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
