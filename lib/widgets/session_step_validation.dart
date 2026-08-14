import 'package:flutter/material.dart';

import '../models/training_item.dart';

class SessionStepValidation extends StatelessWidget {
  const SessionStepValidation({
    super.key,
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
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Text(label, style: const TextStyle(fontSize: 16)),
    ),
  );
}
