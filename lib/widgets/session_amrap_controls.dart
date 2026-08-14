import 'package:flutter/material.dart';

import '../services/amrap_execution_state.dart';
import '../utils/formatters.dart';

class SessionAmrapControls extends StatelessWidget {
  const SessionAmrapControls({
    super.key,
    required this.state,
    required this.onRecordLap,
    required this.onUndoLastLap,
  });

  final AmrapExecutionSnapshot state;
  final VoidCallback onRecordLap;
  final VoidCallback onUndoLastLap;

  @override
  Widget build(BuildContext context) {
    final lastLap = state.lastCompletedLap;
    return Column(
      children: [
        _MetricRow(
          label: 'Tours terminés',
          value: '${state.completedLapCount}',
        ),
        _MetricRow(
          label: 'Tour courant',
          value: formatDuration(state.currentLapDuration),
        ),
        const SizedBox(height: 20),
        FilledButton(
          key: const Key('amrap-record-lap-button'),
          onPressed: state.canRecordLap ? onRecordLap : null,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Text('+ Tour terminé', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: state.limitReached
              ? const Text('Limite de 999 tours atteinte')
              : lastLap != null && state.canUndoLastLap
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'Tour ${state.completedLapCount} enregistré · '
                        '${formatDuration(lastLap)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      key: const Key('amrap-undo-lap-button'),
                      onPressed: onUndoLastLap,
                      child: const Text('Annuler'),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
