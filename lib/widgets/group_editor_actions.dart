import 'package:flutter/material.dart';

/// Barre d'actions basse de [GroupEditor] : ajout d'un exercice ou d'une
/// pause, puis bouton d'enregistrement du groupe.
class GroupEditorActions extends StatelessWidget {
  final VoidCallback onAddExercise;
  final VoidCallback onAddRest;
  final VoidCallback onSave;
  final String actionLabel;
  final bool showItemActions;

  const GroupEditorActions({
    super.key,
    required this.onAddExercise,
    required this.onAddRest,
    required this.onSave,
    this.actionLabel = 'Enregistrer',
    this.showItemActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showItemActions) ...[
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onAddExercise,
                icon: const Icon(Icons.fitness_center),
                label: const Text("Exercice"),
              ),
              OutlinedButton.icon(
                onPressed: onAddRest,
                icon: const Icon(Icons.timer),
                label: const Text("Pause"),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: onSave, child: Text(actionLabel)),
        ),
      ],
    );
  }
}
