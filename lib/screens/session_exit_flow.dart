import 'package:flutter/material.dart';

import '../services/session_controller.dart';
import '../widgets/dialogs/exit_session_dialog.dart';

/// Coordonne le dialogue Retour avec l'état actif ou en préparation.
Future<void> handleSessionExit(
  BuildContext context,
  SessionController controller,
) async {
  final wasPreparing = controller.preparing;
  final wasPaused = controller.paused;
  if (wasPreparing && !wasPaused) controller.togglePause();

  final choice = await showExitSessionDialog(context, preparing: wasPreparing);
  if (!context.mounted) return;

  if (choice == ExitSessionChoice.finish) {
    await controller.finishSession(earlyExit: true);
  } else if (choice == ExitSessionChoice.abandon) {
    await controller.abandon();
    if (context.mounted) Navigator.pop(context);
  } else if (wasPreparing && !wasPaused && controller.preparing) {
    controller.togglePause();
  }
}
