import 'package:flutter/material.dart';

import '../../models/training.dart';
import 'confirm_dialog.dart';

/// Demande la confirmation standard avant de supprimer une séance.
Future<bool> confirmTrainingDeletion(
  BuildContext context, {
  required Training training,
  required Future<void> Function() onDelete,
}) => confirmAndDelete(
  context,
  title: "Supprimer la séance ?",
  content: 'Cette action est irréversible. Supprimer "${training.name}" ?',
  onDelete: onDelete,
);
