import 'package:flutter/material.dart';

import '../controllers/training_export_selection_controller.dart';

class TrainingExportSelection extends StatelessWidget {
  const TrainingExportSelection({
    super.key,
    required this.controller,
    required this.enabled,
  });

  final TrainingExportSelectionController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton(
              onPressed: enabled && !controller.allSelected
                  ? controller.selectAll
                  : null,
              child: const Text('Tout cocher'),
            ),
            TextButton(
              onPressed: enabled && controller.hasSelection
                  ? controller.clearAll
                  : null,
              child: const Text('Tout décocher'),
            ),
          ],
        ),
        for (var index = 0; index < controller.trainings.length; index++)
          Semantics(
            label:
                '${controller.trainings[index].name}, '
                '${controller.isSelected(index) ? 'cochée' : 'non cochée'}',
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(controller.trainings[index].name),
              value: controller.isSelected(index),
              onChanged: enabled
                  ? (value) => controller.setSelected(index, value ?? false)
                  : null,
            ),
          ),
      ],
    ),
  );
}
