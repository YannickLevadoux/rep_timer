import 'package:flutter/material.dart';

import '../../validation/validation_contract.dart';

Future<int?> showPreSessionCountdownDialog(
  BuildContext context, {
  required int initialValue,
}) => showDialog<int>(
  context: context,
  builder: (_) => _PreSessionCountdownDialog(initialValue: initialValue),
);

String preSessionCountdownLabel(int seconds) => switch (seconds) {
  0 => 'Désactivé',
  1 => '1 seconde',
  _ => '$seconds secondes',
};

class _PreSessionCountdownDialog extends StatefulWidget {
  const _PreSessionCountdownDialog({required this.initialValue});

  final int initialValue;

  @override
  State<_PreSessionCountdownDialog> createState() =>
      _PreSessionCountdownDialogState();
}

class _PreSessionCountdownDialogState
    extends State<_PreSessionCountdownDialog> {
  late int _value = widget.initialValue;

  void _change(int delta) => setState(() => _value += delta);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Compte à rebours'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const Key('decrease-pre-session-countdown'),
                tooltip: 'Diminuer le compte à rebours',
                onPressed: _value > 0 ? () => _change(-1) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              SizedBox(
                width: 110,
                child: Text(
                  preSessionCountdownLabel(_value),
                  key: const Key('pre-session-countdown-dialog-value'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                key: const Key('increase-pre-session-countdown'),
                tooltip: 'Augmenter le compte à rebours',
                onPressed:
                    _value < BusinessLimits.maximumPreSessionCountdownSeconds
                    ? () => _change(1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '0 = désactivé',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _value),
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
