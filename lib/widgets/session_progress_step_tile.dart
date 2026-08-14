import 'package:flutter/material.dart';

import '../models/session_step.dart';
import '../models/group_type.dart';
import '../models/training_item.dart';
import '../utils/exercise_icons.dart';

String formatSessionStepDetail(SessionStep step) {
  final item = step.item;
  if (item.type == ItemType.rest) {
    return '${item.duration?.inSeconds ?? 0} s';
  }
  if (item.isFreeDuration) return 'Durée libre';
  return item.duration != null
      ? '${item.duration!.inSeconds} s'
      : '× ${item.repetitions ?? 0}';
}

class SessionProgressStepTile extends StatelessWidget {
  final SessionStep step;
  final bool done;
  final bool isCurrent;
  final AnimationController blinkController;
  final VoidCallback onSelect;

  const SessionProgressStepTile({
    super.key,
    required this.step,
    required this.done,
    required this.isCurrent,
    required this.blinkController,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final leadingIcon = Icon(
      done ? Icons.check_circle : Icons.radio_button_unchecked,
      color: done
          ? Colors.green
          : isCurrent
          ? colors.primary
          : colors.outline,
    );
    final title = _StepTitle(step: step, isCurrent: isCurrent);
    final blinkOpacity = Tween<double>(begin: 1, end: 0.35).animate(
      CurvedAnimation(parent: blinkController, curve: Curves.easeInOut),
    );

    return ListTile(
      leading: isCurrent
          ? FadeTransition(opacity: blinkOpacity, child: leadingIcon)
          : leadingIcon,
      title: isCurrent
          ? FadeTransition(opacity: blinkOpacity, child: title)
          : title,
      subtitle: Text(
        '${step.group.name} · ${_occurrenceLabel(step)} · '
        '${formatSessionStepDetail(step)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isCurrent
          ? null
          : IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Lancer cet exercice',
              onPressed: onSelect,
            ),
      onTap: onSelect,
    );
  }

  String _occurrenceLabel(SessionStep step) => switch (step.group.type) {
    GroupType.tabata => 'cycle ${step.roundIndex}/${step.totalRounds}',
    GroupType.emom => 'minute ${step.roundIndex}/${step.totalRounds}',
    GroupType.amrap => 'AMRAP',
    _ => 'répétition ${step.roundIndex}/${step.totalRounds}',
  };
}

class _StepTitle extends StatelessWidget {
  final SessionStep step;
  final bool isCurrent;

  const _StepTitle({required this.step, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          step.item.type == ItemType.exercise
              ? iconForExercise(step.item.iconName)
              : Icons.timer,
          size: 18,
          color: isCurrent ? colors.primary : colors.outline,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            step.item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? colors.primary : null,
            ),
          ),
        ),
      ],
    );
  }
}
