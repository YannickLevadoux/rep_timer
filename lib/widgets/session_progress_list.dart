import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/session_step.dart';
import 'section_divider.dart';
import 'session_progress_step_tile.dart';

/// Décrit la structure et la géométrie de la liste de progression sans
/// construire ses widgets. Une entrée supplémentaire est insérée au début de
/// chaque groupe afin de conserver un rendu paresseux même sur 10 000 étapes.
class SessionProgressListLayout {
  final List<_ProgressListEntry> _entries;
  final List<int> _stepListIndices;

  factory SessionProgressListLayout(List<SessionStep> steps) {
    final (entries, stepListIndices) = _buildLayout(steps);
    return SessionProgressListLayout._(entries, stepListIndices);
  }

  const SessionProgressListLayout._(this._entries, this._stepListIndices);

  int get itemCount => _entries.length;

  double stepOffset(BuildContext context, int stepIndex) {
    final extents = _progressItemExtents(context);
    final listIndex = _stepListIndices[stepIndex];
    final precedingSeparatorCount = listIndex - stepIndex;
    return stepIndex * extents.step +
        precedingSeparatorCount * extents.separator;
  }
}

/// Liste paresseuse des étapes et des séparateurs de groupes.
class SessionProgressList extends StatelessWidget {
  final SessionProgressListLayout layout;
  final List<SessionStep> steps;
  final List<bool> completed;
  final int currentIndex;
  final AnimationController blinkController;
  final ScrollController scrollController;
  final ValueChanged<int> onSelectStep;

  const SessionProgressList({
    super.key,
    required this.layout,
    required this.steps,
    required this.completed,
    required this.currentIndex,
    required this.blinkController,
    required this.scrollController,
    required this.onSelectStep,
  });

  @override
  Widget build(BuildContext context) {
    final extents = _progressItemExtents(context);

    return ListView.builder(
      controller: scrollController,
      itemExtentBuilder: (index, _) =>
          layout._entries[index].isSeparator ? extents.separator : extents.step,
      itemCount: layout.itemCount,
      itemBuilder: (context, index) {
        final entry = layout._entries[index];
        if (entry.isSeparator) {
          return SectionDivider(
            key: ValueKey('progress-group-separator-${entry.stepIndex}'),
            label: steps[entry.stepIndex].group.name,
          );
        }

        final stepIndex = entry.stepIndex;
        return SessionProgressStepTile(
          step: steps[stepIndex],
          done: completed[stepIndex],
          isCurrent: stepIndex == currentIndex,
          blinkController: blinkController,
          onSelect: () => onSelectStep(stepIndex),
        );
      },
    );
  }
}

typedef _ProgressItemExtents = ({double separator, double step});

_ProgressItemExtents _progressItemExtents(BuildContext context) {
  final theme = Theme.of(context);
  final tileTheme = ListTileTheme.of(context);
  final textScaler = MediaQuery.textScalerOf(context);
  final textDirection = Directionality.of(context);

  double lineHeight(TextStyle style, {TextScaler? scaler}) {
    final painter = TextPainter(
      text: TextSpan(text: 'Ag', style: style),
      maxLines: 1,
      textDirection: textDirection,
      textScaler: scaler ?? textScaler,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }

  final titleStyle = tileTheme.titleTextStyle ?? theme.textTheme.bodyLarge!;
  final subtitleStyle =
      tileTheme.subtitleTextStyle ?? theme.textTheme.bodyMedium!;
  final titleHeight = lineHeight(titleStyle);
  final subtitleHeight = lineHeight(subtitleStyle);
  final unscaledTitleHeight = lineHeight(
    titleStyle,
    scaler: TextScaler.noScaling,
  );
  final unscaledSubtitleHeight = lineHeight(
    subtitleStyle,
    scaler: TextScaler.noScaling,
  );
  final hasScaledText =
      titleHeight > unscaledTitleHeight ||
      subtitleHeight > unscaledSubtitleHeight;
  final defaultStepExtent = 72.0 + theme.visualDensity.baseSizeAdjustment.dy;
  final stepExtent = math.max(
    tileTheme.minTileHeight ?? defaultStepExtent,
    defaultStepExtent +
        math.max(0, titleHeight - unscaledTitleHeight) +
        2 * math.max(0, subtitleHeight - unscaledSubtitleHeight) +
        (hasScaledText ? unscaledSubtitleHeight : 0),
  );
  final separatorLabelHeight = lineHeight(theme.textTheme.labelMedium!);

  return (separator: math.max(16, separatorLabelHeight) + 32, step: stepExtent);
}

class _ProgressListEntry {
  final int stepIndex;
  final bool isSeparator;

  const _ProgressListEntry.step(this.stepIndex) : isSeparator = false;
  const _ProgressListEntry.separator(this.stepIndex) : isSeparator = true;
}

(List<_ProgressListEntry>, List<int>) _buildLayout(List<SessionStep> steps) {
  final entries = <_ProgressListEntry>[];
  final stepListIndices = List<int>.filled(steps.length, 0);

  for (var index = 0; index < steps.length; index++) {
    final startsGroup =
        index == 0 || steps[index - 1].group.id != steps[index].group.id;
    if (startsGroup) entries.add(_ProgressListEntry.separator(index));

    stepListIndices[index] = entries.length;
    entries.add(_ProgressListEntry.step(index));
  }

  return (entries, stepListIndices);
}
