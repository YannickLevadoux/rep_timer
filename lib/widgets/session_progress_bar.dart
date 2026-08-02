import 'dart:async';

import 'package:flutter/material.dart';

/// Barre de progression tactile qui expose le rang courant dans une bulle
/// temporaire et dans l'arbre d'accessibilité.
class SessionProgressBar extends StatefulWidget {
  const SessionProgressBar({
    super.key,
    required this.currentIndex,
    required this.totalSteps,
  });

  final int currentIndex;
  final int totalSteps;

  @override
  State<SessionProgressBar> createState() => _SessionProgressBarState();
}

class _SessionProgressBarState extends State<SessionProgressBar> {
  Timer? _bubbleTimer;
  bool _showBubble = false;

  double get _progress => (widget.currentIndex + 1) / widget.totalSteps;

  String get _label =>
      'Exercice ${widget.currentIndex + 1} / ${widget.totalSteps}';

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    super.dispose();
  }

  void _showDetails() {
    _bubbleTimer?.cancel();
    setState(() => _showBubble = true);
    _bubbleTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showBubble = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _label,
      button: true,
      child: GestureDetector(
        key: const Key('session-progress-bar'),
        behavior: HitTestBehavior.opaque,
        onTap: _showDetails,
        child: SizedBox(
          height: 48,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Center(
                    child: ExcludeSemantics(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 8,
                        ),
                      ),
                    ),
                  ),
                  if (_showBubble)
                    _ProgressBubble(
                      left: _bubbleLeft(constraints.maxWidth),
                      width: constraints.maxWidth.clamp(0, 136),
                      label: _label,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  double _bubbleLeft(double availableWidth) {
    const bubbleWidth = 136.0;
    final anchor = availableWidth * _progress;
    final maxLeft = availableWidth - bubbleWidth;
    return (anchor - bubbleWidth / 2).clamp(0.0, maxLeft < 0 ? 0.0 : maxLeft);
  }
}

class _ProgressBubble extends StatelessWidget {
  const _ProgressBubble({
    required this.left,
    required this.width,
    required this.label,
  });

  final double left;
  final double width;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Positioned(
      key: const Key('progress-bubble'),
      top: 0,
      left: left,
      width: width,
      child: Material(
        color: colors.inverseSurface,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.onInverseSurface),
          ),
        ),
      ),
    );
  }
}
