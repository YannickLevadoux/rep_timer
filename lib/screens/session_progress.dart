import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/session_step.dart';
import '../widgets/section_divider.dart';
import '../widgets/session_progress_step_tile.dart';

/// Vue détaillée de la progression d'une séance en cours : exercices
/// terminés (coche verte) vs en attente. Poussé par-dessus l'écran de
/// séance, qui continue de tourner en arrière-plan.
class SessionProgressScreen extends StatefulWidget {
  final List<SessionStep> steps;
  final List<bool> completed; // référence partagée avec l'écran de séance
  final int Function() currentIndexProvider;

  // Même AnimationController que l'écran d'exécution : garantit un
  // clignotement synchronisé, et se fige/reprend automatiquement avec
  // la pause (gérée côté écran de séance).
  final AnimationController blinkController;

  // Demande à l'écran de séance de changer d'exercice courant. La
  // navigation manuelle ne modifie jamais le statut "terminé".
  final void Function(int index) onSelectStep;
  final Future<bool> Function(int index)? onBeforeSelectStep;

  const SessionProgressScreen({
    super.key,
    required this.steps,
    required this.completed,
    required this.currentIndexProvider,
    required this.blinkController,
    required this.onSelectStep,
    this.onBeforeSelectStep,
  });

  @override
  State<SessionProgressScreen> createState() => _SessionProgressScreenState();
}

class _SessionProgressScreenState extends State<SessionProgressScreen> {
  static const _currentStepAlignment = 0.3;

  Timer? _refreshTimer;
  final ScrollController _scrollController = ScrollController();
  late final int _initialCurrentIndex;
  late final List<_ProgressListEntry> _listEntries;
  late final List<int> _stepListIndices;

  @override
  void initState() {
    super.initState();

    _initialCurrentIndex = widget.currentIndexProvider();
    final (listEntries, stepListIndices) = _buildListEntries(widget.steps);
    _listEntries = listEntries;
    _stepListIndices = stepListIndices;

    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    // Positionne automatiquement la liste sur l'exercice en cours à
    // l'ouverture de l'écran.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToInitialCurrent(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToInitialCurrent() {
    if (_initialCurrentIndex < 0 ||
        _initialCurrentIndex >= widget.steps.length ||
        !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final extents = _progressItemExtents(context);
    final currentListIndex = _stepListIndices[_initialCurrentIndex];
    final precedingSeparatorCount = currentListIndex - _initialCurrentIndex;
    final currentStepOffset =
        _initialCurrentIndex * extents.step +
        precedingSeparatorCount * extents.separator;
    final targetOffset =
        currentStepOffset - position.viewportDimension * _currentStepAlignment;

    unawaited(_animateToInitialCurrent(targetOffset));
  }

  Future<void> _animateToInitialCurrent(double targetOffset) async {
    var position = _scrollController.position;
    await _scrollController.animateTo(
      targetOffset
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble(),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    if (!mounted || !_scrollController.hasClients) return;

    // Une liste à hauteurs variées affine son étendue maximale à mesure que
    // de nouveaux éléments sont rendus. Une courte correction garantit donc
    // la limite exacte en fin de très longue séance.
    position = _scrollController.position;
    final correctedOffset = targetOffset
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((correctedOffset - position.pixels).abs() < 0.5) return;

    await _scrollController.animateTo(
      correctedOffset,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  SessionProgressStepTile _buildStepTile(
    int index, {
    required bool isCurrent,
    required bool done,
    VoidCallback? onSelect,
  }) => SessionProgressStepTile(
    step: widget.steps[index],
    done: done,
    isCurrent: isCurrent,
    blinkController: widget.blinkController,
    onSelect: onSelect ?? () => _confirmAndSelect(index),
  );

  Future<void> _confirmAndSelect(int index) async {
    if (index == widget.currentIndexProvider()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Changer d'exercice ?"),
          content: const Text(
            "La progression actuelle de la séance sera modifiée. Continuer ?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Continuer"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final beforeSelect = widget.onBeforeSelectStep;
    if (beforeSelect != null && !await beforeSelect(index)) return;

    widget.onSelectStep(index);

    if (!mounted) return;
    // Retour à l'écran d'exécution sur le nouvel exercice choisi.
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.currentIndexProvider();
    final doneCount = widget.completed.where((c) => c).length;
    final extents = _progressItemExtents(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Progression ($doneCount/${widget.steps.length})"),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemExtentBuilder: (index, _) =>
            _listEntries[index].isSeparator ? extents.separator : extents.step,
        itemCount: _listEntries.length,
        itemBuilder: (context, index) {
          final entry = _listEntries[index];
          if (entry.isSeparator) {
            return SectionDivider(
              key: ValueKey('progress-group-separator-${entry.stepIndex}'),
              label: widget.steps[entry.stepIndex].group.name,
            );
          }

          final stepIndex = entry.stepIndex;
          return _buildStepTile(
            stepIndex,
            done: widget.completed[stepIndex],
            isCurrent: stepIndex == currentIndex,
          );
        },
      ),
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

(List<_ProgressListEntry>, List<int>) _buildListEntries(
  List<SessionStep> steps,
) {
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
