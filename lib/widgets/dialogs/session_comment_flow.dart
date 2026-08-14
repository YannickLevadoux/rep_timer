import 'package:flutter/material.dart';

import '../../services/json_prefs_storage.dart';
import '../../services/session_controller.dart';
import '../../utils/snack.dart';
import '../../validation/business_validation.dart';
import 'comment_dialog.dart';

Future<void> editCurrentSessionComment(
  BuildContext context,
  SessionController controller,
) async {
  final result = await showCommentDialog(
    context,
    initialComment: controller.currentStep.item.comment ?? '',
  );
  if (result == null) return;
  try {
    await controller.updateComment(result);
  } on BusinessValidationException {
    return;
  } on StorageMutationBlockedException {
    if (!context.mounted) return;
    showSnack(
      context,
      "Commentaire non enregistré : les séances stockées n'ont pas pu "
      'être lues intégralement.',
    );
  }
}
