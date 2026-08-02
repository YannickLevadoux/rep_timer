import 'package:flutter/material.dart';

/// Groupe centré des commandes précédent, pause/reprise et suivant.
class SessionNavigationControls extends StatelessWidget {
  const SessionNavigationControls({
    super.key,
    required this.width,
    required this.controlSize,
    required this.gap,
    required this.scale,
    required this.paused,
    required this.previousEnabled,
    required this.nextEnabled,
    required this.onPrevious,
    required this.onNext,
    required this.onTogglePause,
  });

  final double width;
  final double controlSize;
  final double gap;
  final double scale;
  final bool paused;
  final bool previousEnabled;
  final bool nextEnabled;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTogglePause;

  @override
  Widget build(BuildContext context) {
    final actionLabel = paused ? 'Reprendre' : 'Pause';

    return SizedBox(
      width: width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NavigationButton(
            buttonKey: const Key('previous-step-button'),
            size: controlSize,
            iconSize: 24 * scale,
            icon: Icons.skip_previous,
            tooltip: 'Exercice précédent',
            onPressed: previousEnabled ? onPrevious : null,
          ),
          SizedBox(width: gap),
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
                    size: 24 * scale,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: gap),
          _NavigationButton(
            buttonKey: const Key('next-step-button'),
            size: controlSize,
            iconSize: 24 * scale,
            icon: Icons.skip_next,
            tooltip: 'Exercice suivant',
            onPressed: nextEnabled ? onNext : null,
          ),
        ],
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.buttonKey,
    required this.size,
    required this.iconSize,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final Key buttonKey;
  final double size;
  final double iconSize;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: IconButton(
        key: buttonKey,
        iconSize: iconSize,
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
