import 'package:flutter/material.dart';

import '../models/notification_mode.dart';
import 'session_command_row.dart';

/// Composition présentative affichée avant le premier exercice.
class SessionPreparingBody extends StatelessWidget {
  const SessionPreparingBody({
    super.key,
    required this.secondsRemaining,
    required this.paused,
    required this.notificationMode,
    required this.blinkOpacity,
    required this.onTogglePause,
    required this.onSkip,
    required this.onCycleNotificationMode,
  });

  final int secondsRemaining;
  final bool paused;
  final NotificationMode notificationMode;
  final Animation<double> blinkOpacity;
  final VoidCallback onTogglePause;
  final VoidCallback onSkip;
  final VoidCallback onCycleNotificationMode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          SessionCommandRow(
            globalElapsed: Duration.zero,
            paused: paused,
            notificationMode: notificationMode,
            previousEnabled: false,
            previousVisible: false,
            nextEnabled: true,
            nextTooltip: 'Passer le compte à rebours',
            showGlobalTimer: false,
            onPrevious: _noop,
            onNext: onSkip,
            onTogglePause: onTogglePause,
            onCycleNotificationMode: onCycleNotificationMode,
          ),
          const SizedBox(height: 48),
          Semantics(
            liveRegion: true,
            label: 'Début du compte à rebours',
            child: ExcludeSemantics(
              child: Text(
                '$secondsRemaining',
                key: const Key('pre-session-countdown'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: blinkOpacity,
            child: Text(
              'Prêt ?',
              key: const Key('pre-session-ready-label'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}
