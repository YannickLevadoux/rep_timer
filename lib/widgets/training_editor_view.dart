import 'package:flutter/material.dart';

import '../controllers/training_editor_controller.dart';
import 'exercise_group_card.dart';

class TrainingEditorView extends StatelessWidget {
  const TrainingEditorView({
    super.key,
    required this.controller,
    required this.canDeleteTraining,
    required this.onDeleteTraining,
    required this.onEditName,
    required this.onAddGroup,
    required this.onEditGroup,
    required this.onDeleteGroup,
    required this.onSave,
  });

  final TrainingEditorController controller;
  final bool canDeleteTraining;
  final VoidCallback onDeleteTraining;
  final VoidCallback onEditName;
  final VoidCallback onAddGroup;
  final ValueChanged<int> onEditGroup;
  final ValueChanged<int> onDeleteGroup;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _TrainingTitle(name: controller.name, onEditName: onEditName),
        actions: [
          if (canDeleteTraining)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: "Supprimer la séance",
              onPressed: onDeleteTraining,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: _GroupsList(
                controller: controller,
                onEditGroup: onEditGroup,
                onDeleteGroup: onDeleteGroup,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddGroup,
                icon: const Icon(Icons.add),
                label: const Text("Ajouter un groupe"),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: controller.saving ? null : onSave,
                child: controller.saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Enregistrer"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingTitle extends StatelessWidget {
  const _TrainingTitle({required this.name, required this.onEditName});

  final String name;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) {
    final isNewTraining = name.isEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            isNewTraining ? "Nouvelle séance" : name,
            overflow: TextOverflow.ellipsis,
            style: isNewTraining
                ? const TextStyle(fontStyle: FontStyle.italic)
                : null,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: "Modifier le nom de la séance",
          onPressed: onEditName,
        ),
      ],
    );
  }
}

class _GroupsList extends StatelessWidget {
  const _GroupsList({
    required this.controller,
    required this.onEditGroup,
    required this.onDeleteGroup,
  });

  final TrainingEditorController controller;
  final ValueChanged<int> onEditGroup;
  final ValueChanged<int> onDeleteGroup;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      scrollController: controller.groupsScrollController,
      buildDefaultDragHandles: false,
      itemCount: controller.groups.length,
      onReorderItem: controller.reorderGroups,
      itemBuilder: (context, index) {
        final group = controller.groups[index];

        return ExerciseGroupCard(
          key: ValueKey(group.id),
          group: group,
          index: index,
          expanded: controller.isExpanded(group.id),
          hasFollowingGroup: index + 1 < controller.groups.length,
          onExpanded: (expanded) {
            controller.setExpanded(group.id, expanded);
          },
          onDelete: () => onDeleteGroup(index),
          onEdit: () => onEditGroup(index),
        );
      },
    );
  }
}
