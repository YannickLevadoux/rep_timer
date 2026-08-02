import 'dart:async';

import 'package:flutter/material.dart';

import '../models/notification_mode.dart';
import '../models/session_step.dart';
import '../models/training_item.dart';
import '../utils/exercise_icons.dart';
import '../utils/formatters.dart';
import '../utils/notification_mode_icons.dart';
import 'section_divider.dart';
import 'session_comment_section.dart';

/// Corps principal de l'écran d'exécution d'une séance.
///
/// Toute la logique de séance reste dans le contrôleur et l'écran parent : ce
/// widget ne fait qu'afficher l'état reçu et transmettre les actions.
class SessionRunningBody extends StatefulWidget {
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
  State<SessionRunningBody> createState() => _SessionRunningBodyState();
}

class _SessionRunningBodyState extends State<SessionRunningBody> {
  Timer? _progressBubbleTimer;
  bool _showProgressBubble = false;

  @override
  void dispose() {
    _progressBubbleTimer?.cancel();
    super.dispose();
  }

  void _showProgressDetails() {
    _progressBubbleTimer?.cancel();
    setState(() => _showProgressBubble = true);
    _progressBubbleTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showProgressBubble = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.step.item;
    final isDurationBased = item.duration != null;
    final isFreeDuration = item.isFreeDuration;
    final remaining = isDurationBased
        ? item.duration! - widget.stepElapsed
        : Duration.zero;
    final displayedStepTime = isDurationBased ? remaining : widget.stepElapsed;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          _CommandRow(
            globalElapsed: widget.globalElapsed,
            paused: widget.paused,
            notificationMode: widget.notificationMode,
            previousEnabled: widget.currentIndex > 0,
            nextEnabled: widget.currentIndex < widget.totalSteps - 1,
            onPrevious: widget.onPrevious,
            onNext: widget.onNext,
            onTogglePause: widget.onTogglePause,
            onCycleNotificationMode: widget.onCycleNotificationMode,
          ),
          const SizedBox(height: 4),
          _ProgressBar(
            currentIndex: widget.currentIndex,
            totalSteps: widget.totalSteps,
            showBubble: _showProgressBubble,
            onTap: _showProgressDetails,
          ),

          const SectionDivider(label: 'Prochain'),
          Text(
            _nextStepLabel(widget.nextStep),
            key: const Key('next-step-label'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),

          const SectionDivider(label: 'En cours'),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.step.group.name,
                  key: const Key('current-group-name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tour ${widget.step.roundIndex}/${widget.step.totalRounds}',
                key: const Key('round-label'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            formatDuration(displayedStepTime),
            key: const Key('step-timer'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // L'icône, le nom et le commentaire conservent la même animation
          // partagée pour rester parfaitement synchronisés.
          FadeTransition(
            opacity: widget.blinkOpacity,
            child: Column(
              children: [
                Icon(
                  item.type == ItemType.exercise
                      ? iconForExercise(item.iconName)
                      : Icons.timer,
                  key: const Key('current-step-icon'),
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
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
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          SessionCommentSection(
            item: item,
            blinkOpacity: widget.blinkOpacity,
            onEditComment: widget.onEditComment,
          ),

          if (!isDurationBased && !isFreeDuration) ...[
            const SizedBox(height: 16),
            Text(
              '× ${item.repetitions ?? 0}',
              key: const Key('repetitions-target'),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: widget.paused ? null : widget.onComplete,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                child: Text(
                  'Répétitions effectuées',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],

          if (isFreeDuration) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: widget.paused ? null : widget.onComplete,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                child: Text(
                  'Exercice effectué',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
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

class _CommandRow extends StatelessWidget {
  const _CommandRow({
    required this.globalElapsed,
    required this.paused,
    required this.notificationMode,
    required this.previousEnabled,
    required this.nextEnabled,
    required this.onPrevious,
    required this.onNext,
    required this.onTogglePause,
    required this.onCycleNotificationMode,
  });

  final Duration globalElapsed;
  final bool paused;
  final NotificationMode notificationMode;
  final bool previousEnabled;
  final bool nextEnabled;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTogglePause;
  final VoidCallback onCycleNotificationMode;

  @override
  Widget build(BuildContext context) {
    final actionLabel = paused ? 'Reprendre' : 'Pause';
    final outlineColor = Theme.of(context).colorScheme.outline;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Les commandes sont agrandies dès que les deux zones latérales
        // peuvent également conserver cette taille. Sur un écran étroit,
        // elles reviennent à la cible tactile minimale de 48 px et l'écart
        // est réduit progressivement avant de disparaître si nécessaire.
        final useLargerControls = constraints.maxWidth >= 291;
        final controlSize = useLargerControls ? 55.0 : 48.0;
        final controlGap = useLargerControls
            ? 8.0
            : ((constraints.maxWidth - 240) / 2).clamp(0.0, 4.0);
        final controlsWidth = controlSize * 3 + controlGap * 2;
        final sideWidth = (constraints.maxWidth - controlsWidth) / 2;
        final sizeScale = controlSize / 48;

        return SizedBox(
          height: controlSize,
          child: Row(
            children: [
              SizedBox(
                width: sideWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: outlineColor,
                          fontSize:
                              (Theme.of(
                                    context,
                                  ).textTheme.labelSmall?.fontSize ??
                                  11) *
                              sizeScale,
                        ),
                      ),
                      Text(
                        formatDuration(globalElapsed),
                        key: const Key('global-timer'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: outlineColor,
                              fontSize:
                                  (Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.fontSize ??
                                      16) *
                                  sizeScale,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: controlsWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox.square(
                      dimension: controlSize,
                      child: IconButton(
                        key: const Key('previous-step-button'),
                        iconSize: 24 * sizeScale,
                        icon: const Icon(Icons.skip_previous),
                        tooltip: 'Exercice précédent',
                        onPressed: previousEnabled ? onPrevious : null,
                      ),
                    ),
                    SizedBox(width: controlGap),
                    Semantics(
                      button: true,
                      label: actionLabel,
                      child: Tooltip(
                        message: actionLabel,
                        child: SizedBox.square(
                          dimension: controlSize,
                          child: FilledButton(
                            key: const Key('pause-resume-button'),
                            onPressed: onTogglePause,
                            style: FilledButton.styleFrom(
                              minimumSize: Size.square(controlSize),
                              maximumSize: Size.square(controlSize),
                              padding: EdgeInsets.zero,
                              shape: const CircleBorder(),
                            ),
                            child: Icon(
                              paused ? Icons.play_arrow : Icons.pause,
                              size: 24 * sizeScale,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: controlGap),
                    SizedBox.square(
                      dimension: controlSize,
                      child: IconButton(
                        key: const Key('next-step-button'),
                        iconSize: 24 * sizeScale,
                        icon: const Icon(Icons.skip_next),
                        tooltip: 'Exercice suivant',
                        onPressed: nextEnabled ? onNext : null,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: sideWidth,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox.square(
                    dimension: controlSize,
                    child: IconButton(
                      key: const Key('notification-mode-button'),
                      icon: Icon(
                        iconForNotificationMode(notificationMode),
                        size: 20 * sizeScale,
                      ),
                      tooltip: 'Notifications : ${notificationMode.label}',
                      onPressed: onCycleNotificationMode,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.currentIndex,
    required this.totalSteps,
    required this.showBubble,
    required this.onTap,
  });

  final int currentIndex;
  final int totalSteps;
  final bool showBubble;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = (currentIndex + 1) / totalSteps;
    final label = 'Exercice ${currentIndex + 1} / $totalSteps';

    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        key: const Key('session-progress-bar'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const bubbleWidth = 136.0;
              final anchor = constraints.maxWidth * progress;
              final maxLeft = constraints.maxWidth - bubbleWidth;
              final bubbleLeft = (anchor - bubbleWidth / 2).clamp(
                0.0,
                maxLeft < 0 ? 0.0 : maxLeft,
              );

              return Stack(
                children: [
                  Center(
                    child: ExcludeSemantics(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                        ),
                      ),
                    ),
                  ),
                  if (showBubble)
                    Positioned(
                      key: const Key('progress-bubble'),
                      top: 0,
                      left: bubbleLeft,
                      width: constraints.maxWidth < bubbleWidth
                          ? constraints.maxWidth
                          : bubbleWidth,
                      child: Material(
                        color: Theme.of(context).colorScheme.inverseSurface,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onInverseSurface,
                                ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
