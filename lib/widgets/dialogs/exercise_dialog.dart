import 'package:flutter/material.dart';

import '../../models/training_item.dart';
import '../../validation/business_validation.dart';
import '../exercise_form.dart';
import '../exercise_form_controller.dart';

/// Ouvre le formulaire de création ou de modification d'un exercice.
Future<TrainingItem?> showExerciseDialog(
  BuildContext context, {
  TrainingItem? initial,
  String defaultName = '',
  bool repetitionsDefinedByGroup = false,
  int repetitionFallback = BusinessLimits.minimumCount,
}) => showDialog<TrainingItem>(
  context: context,
  builder: (context) => _ExerciseDialog(
    initial: initial,
    defaultName: defaultName,
    repetitionsDefinedByGroup: repetitionsDefinedByGroup,
    repetitionFallback: repetitionFallback,
  ),
);

class _ExerciseDialog extends StatefulWidget {
  const _ExerciseDialog({
    required this.initial,
    required this.defaultName,
    required this.repetitionsDefinedByGroup,
    required this.repetitionFallback,
  });

  final TrainingItem? initial;
  final String defaultName;
  final bool repetitionsDefinedByGroup;
  final int repetitionFallback;

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  late final ExerciseFormController controller;

  @override
  void initState() {
    super.initState();
    controller = ExerciseFormController(
      initial: widget.initial,
      defaultName: widget.defaultName,
      repetitionsDefinedByGroup: widget.repetitionsDefinedByGroup,
      repetitionFallback: widget.repetitionFallback,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final result = controller.validateAndBuild();
    if (result != null) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        controller.isEditing ? "Modifier l'exercice" : "Nouvel exercice",
      ),
      content: ExerciseForm(controller: controller),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: Text(controller.isEditing ? 'Valider' : 'Ajouter'),
        ),
      ],
    );
  }
}
