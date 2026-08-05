import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/group_editor_controller.dart';
import '../validation/business_validation.dart';
import 'group_editor_actions.dart';
import 'group_items_list.dart';
import 'rounds_editor.dart';
import 'type_selector.dart';

class GroupEditorView extends StatelessWidget {
  const GroupEditorView({
    super.key,
    required this.controller,
    required this.isNewGroup,
    required this.onOpenSettings,
    required this.onAddExercise,
    required this.onAddRest,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onSave,
    this.nameError,
  });

  final GroupEditorController controller;
  final bool isNewGroup;
  final VoidCallback onOpenSettings;
  final VoidCallback onAddExercise;
  final VoidCallback onAddRest;
  final ValueChanged<int> onEditItem;
  final ValueChanged<int> onDeleteItem;
  final VoidCallback onSave;
  final String? nameError;

  @override
  Widget build(BuildContext context) {
    final group = controller.group;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNewGroup ? "Ajout de groupe" : "Édition du groupe"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Paramètres",
            onPressed: onOpenSettings,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller.nameController,
              autofocus: isNewGroup,
              maxLength: BusinessLimits.maximumNameCharacters,
              maxLengthEnforcement: MaxLengthEnforcement.none,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: "Nom du groupe",
                hintText: "Ex : Échauffement",
                errorText: nameError,
              ),
            ),
            const SizedBox(height: 16),
            TypeSelector(value: group.type, onChanged: controller.setType),
            const SizedBox(height: 16),
            RoundsEditor(rounds: group.rounds, onChanged: controller.setRounds),
            const SizedBox(height: 8),
            Expanded(
              child: GroupItemsList(
                items: group.items,
                onReorder: controller.reorderItems,
                onEdit: onEditItem,
                onDelete: onDeleteItem,
              ),
            ),
            const SizedBox(height: 10),
            GroupEditorActions(
              onAddExercise: onAddExercise,
              onAddRest: onAddRest,
              onSave: onSave,
            ),
          ],
        ),
      ),
    );
  }
}
