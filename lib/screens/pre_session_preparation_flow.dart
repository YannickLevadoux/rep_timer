import 'package:flutter/material.dart';

import '../controllers/pre_session_preparation_controller.dart';
import '../widgets/dialogs/pre_session_countdown_dialog.dart';

ValueChanged<bool> preSessionPreparationHandler(
  BuildContext context,
  PreSessionPreparationController controller,
) => (enabled) async {
  await controller.setEnabled(
    enabled,
    selectDuration: () => showPreSessionCountdownDialog(
      context,
      initialValue: controller.seconds,
    ),
  );
};
