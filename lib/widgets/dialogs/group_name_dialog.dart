import 'package:flutter/material.dart';

import '../../validation/business_validation.dart';
import 'name_dialog.dart';

/// Demande un nouveau nom de groupe en appliquant le contrat métier existant.
Future<String?> showGroupNameDialog(
  BuildContext context, {
  required String initialName,
  String? initialErrorText,
}) {
  return showNameDialog(
    context,
    initialName: initialName,
    field: BusinessField.groupName,
    title: "Nom du groupe",
    label: "Nom du groupe",
    hintText: "Ex : Échauffement",
    initialErrorText: initialErrorText,
  );
}
