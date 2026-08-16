import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/group_editor_controller.dart';
import '../models/group_editor_mode.dart';
import '../models/group_type.dart';
import '../validation/business_validation.dart';
import 'group_editor_fields.dart';
import 'group_type_selection.dart';

class GroupEditorView extends StatelessWidget {
  const GroupEditorView({
    super.key,
    required this.controller,
    required this.mode,
    required this.onOpenSettings,
    required this.onAddExercise,
    required this.onAddRest,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onSave,
    required this.onEditRepetitionSequence,
    required this.onTypeChanged,
    required this.onEditTimedExercise,
    required this.hasFollowingGroup,
    required this.showQuickWarning,
    required this.onDismissQuickWarning,
    this.nameError,
  });

  final GroupEditorController controller;
  final GroupEditorMode mode;
  final VoidCallback onOpenSettings;
  final VoidCallback onAddExercise;
  final VoidCallback onAddRest;
  final ValueChanged<int> onEditItem;
  final ValueChanged<int> onDeleteItem;
  final VoidCallback onSave;
  final VoidCallback onEditRepetitionSequence;
  final ValueChanged<GroupType> onTypeChanged;
  final VoidCallback onEditTimedExercise;
  final bool hasFollowingGroup;
  final bool showQuickWarning;
  final VoidCallback onDismissQuickWarning;
  final String? nameError;

  @override
  Widget build(BuildContext context) {
    final hasSelectedType = controller.hasSelectedType;

    return Scaffold(
      appBar: AppBar(
        title: Text(mode.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Paramètres",
            onPressed: onOpenSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (mode.isQuick && showQuickWarning) ...[
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Cette session ne sera pas enregistrée dans Mes entraînements",
                        ),
                      ),
                      IconButton(
                        onPressed: onDismissQuickWarning,
                        tooltip: "Fermer l'avertissement",
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 36,
                          height: 36,
                        ),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (!hasSelectedType)
              GroupTypeSelection(
                value: null,
                onChanged: onTypeChanged,
                showInitialMessage: true,
              )
            else ...[
              TextField(
                controller: controller.nameController,
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
              GroupTypeSelection(
                value: controller.selectedType,
                onChanged: onTypeChanged,
              ),
              const SizedBox(height: 16),
              GroupEditorFields(
                controller: controller,
                mode: mode,
                onAddExercise: onAddExercise,
                onAddRest: onAddRest,
                onEditItem: onEditItem,
                onDeleteItem: onDeleteItem,
                onSave: onSave,
                onEditRepetitionSequence: onEditRepetitionSequence,
                onEditTimedExercise: onEditTimedExercise,
                hasFollowingGroup: hasFollowingGroup,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
