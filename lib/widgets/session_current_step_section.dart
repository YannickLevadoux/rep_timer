import 'package:flutter/material.dart';

import '../models/session_step.dart';
import '../models/training_item.dart';
import '../utils/exercise_icons.dart';
import '../utils/formatters.dart';
import 'session_comment_section.dart';

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
  });

  final SessionStep step;
  final Duration stepElapsed;
  final bool paused;
  final Animation<double> blinkOpacity;
  final VoidCallback onComplete;
  final VoidCallback onEditComment;

  @override
  Widget build(BuildContext context) {
    final item = step.item;
    final isDurationBased = item.duration != null;
    final displayedTime = isDurationBased
        ? item.duration! - stepElapsed
        : stepElapsed;

    return Column(
      children: [
        _StepMetadata(step: step),
        const SizedBox(height: 12),
        Text(
          formatDuration(displayedTime),
          key: const Key('step-timer'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _StepIdentity(item: item, blinkOpacity: blinkOpacity),
        const SizedBox(height: 4),
        SessionCommentSection(
          item: item,
          blinkOpacity: blinkOpacity,
          onEditComment: onEditComment,
        ),
        _StepValidation(item: item, paused: paused, onComplete: onComplete),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StepMetadata extends StatelessWidget {
  const _StepMetadata({required this.step});

  final SessionStep step;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;

    return Row(
      children: [
        Expanded(
          child: Text(
            step.group.name,
            key: const Key('current-group-name'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Tour ${step.roundIndex}/${step.totalRounds}',
          key: const Key('round-label'),
          style: style,
        ),
      ],
    );
  }
}

class _StepIdentity extends StatelessWidget {
  const _StepIdentity({required this.item, required this.blinkOpacity});

  final TrainingItem item;
  final Animation<double> blinkOpacity;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // L'icône et le nom conservent l'animation partagée avec le commentaire.
    return FadeTransition(
      opacity: blinkOpacity,
      child: Column(
        children: [
          Icon(
            item.type == ItemType.exercise
                ? iconForExercise(item.iconName)
                : Icons.timer,
            key: const Key('current-step-icon'),
            size: 48,
            color: colors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            key: const Key('current-step-name'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepValidation extends StatelessWidget {
  const _StepValidation({
    required this.item,
    required this.paused,
    required this.onComplete,
  });

  final TrainingItem item;
  final bool paused;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    if (item.isFreeDuration) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: _ValidationButton(
          label: 'Exercice effectué',
          onPressed: paused ? null : onComplete,
        ),
      );
    }

    if (item.duration != null) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          '× ${item.repetitions ?? 0}',
          key: const Key('repetitions-target'),
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _ValidationButton(
          label: 'Répétitions effectuées',
          onPressed: paused ? null : onComplete,
        ),
      ],
    );
  }
}

class _ValidationButton extends StatelessWidget {
  const _ValidationButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
