import 'package:flutter/material.dart';

import 'dialogs/pre_session_countdown_dialog.dart';

class PreSessionPreparationToggle extends StatelessWidget {
  const PreSessionPreparationToggle({
    super.key,
    required this.seconds,
    required this.enabled,
    required this.onChanged,
  });

  final int seconds;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final status = enabled ? preSessionCountdownLabel(seconds) : 'Désactivée';
    return ListTile(
      key: const Key('pre-session-preparation-toggle'),
      contentPadding: EdgeInsets.zero,
      title: Text('Préparation : $status'),
      trailing: Switch(
        key: const Key('pre-session-preparation-switch'),
        value: enabled,
        onChanged: onChanged,
      ),
    );
  }
}
