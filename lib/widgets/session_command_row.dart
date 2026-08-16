import 'package:flutter/material.dart';

import '../models/notification_mode.dart';
import '../utils/notification_mode_icons.dart';
import 'session_global_timer.dart';
import 'session_navigation_controls.dart';

/// Affiche le temps global, les commandes de navigation et le mode de
/// notification sur une ligne réellement centrée et responsive.
class SessionCommandRow extends StatelessWidget {
  const SessionCommandRow({
    super.key,
    required this.globalElapsed,
    required this.paused,
    required this.notificationMode,
    required this.previousEnabled,
    required this.nextEnabled,
    required this.onPrevious,
    required this.onNext,
    required this.onTogglePause,
    required this.onCycleNotificationMode,
    this.showGlobalTimer = true,
    this.previousVisible = true,
    this.nextTooltip = 'Exercice suivant',
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
  final bool showGlobalTimer;
  final bool previousVisible;
  final String nextTooltip;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _CommandMetrics.forWidth(constraints.maxWidth);

        return SizedBox(
          height: metrics.controlSize,
          child: Row(
            children: [
              if (showGlobalTimer)
                SessionGlobalTimer(
                  width: metrics.sideWidth,
                  elapsed: globalElapsed,
                  scale: metrics.scale,
                )
              else
                SizedBox(width: metrics.sideWidth),
              SessionNavigationControls(
                width: metrics.controlsWidth,
                controlSize: metrics.controlSize,
                gap: metrics.gap,
                scale: metrics.scale,
                paused: paused,
                previousEnabled: previousEnabled,
                nextEnabled: nextEnabled,
                onPrevious: onPrevious,
                onNext: onNext,
                onTogglePause: onTogglePause,
                previousVisible: previousVisible,
                nextTooltip: nextTooltip,
              ),
              _NotificationButton(
                width: metrics.sideWidth,
                controlSize: metrics.controlSize,
                scale: metrics.scale,
                mode: notificationMode,
                onPressed: onCycleNotificationMode,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CommandMetrics {
  const _CommandMetrics({
    required this.controlSize,
    required this.gap,
    required this.controlsWidth,
    required this.sideWidth,
  });

  factory _CommandMetrics.forWidth(double availableWidth) {
    final useLargerControls = availableWidth >= 291;
    final controlSize = useLargerControls ? 55.0 : 48.0;
    final gap = useLargerControls
        ? 8.0
        : ((availableWidth - 240) / 2).clamp(0.0, 4.0);
    final controlsWidth = controlSize * 3 + gap * 2;

    return _CommandMetrics(
      controlSize: controlSize,
      gap: gap,
      controlsWidth: controlsWidth,
      sideWidth: (availableWidth - controlsWidth) / 2,
    );
  }

  final double controlSize;
  final double gap;
  final double controlsWidth;
  final double sideWidth;

  double get scale => controlSize / 48;
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.width,
    required this.controlSize,
    required this.scale,
    required this.mode,
    required this.onPressed,
  });

  final double width;
  final double controlSize;
  final double scale;
  final NotificationMode mode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: Alignment.centerRight,
        child: SizedBox.square(
          dimension: controlSize,
          child: IconButton(
            key: const Key('notification-mode-button'),
            icon: Icon(iconForNotificationMode(mode), size: 20 * scale),
            tooltip: 'Notifications : ${mode.label}',
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
