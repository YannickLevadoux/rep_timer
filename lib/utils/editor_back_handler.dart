import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/dialogs/confirm_dialog.dart';

Future<void> handleEditorBack(
  BuildContext context, {
  required bool hasUnsavedChanges,
  required FutureOr<void> Function() onSave,
}) async {
  if (!hasUnsavedChanges) {
    Navigator.pop(context);
    return;
  }

  final choice = await showUnsavedChangesDialog(context);
  if (!context.mounted) return;

  switch (choice) {
    case 'save':
      await onSave();
      break;
    case 'discard':
      Navigator.pop(context);
      break;
    case 'cancel':
    default:
      break;
  }
}
