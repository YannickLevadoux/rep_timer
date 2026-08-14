import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/group_editor_controller.dart';
import '../models/group_type.dart';
import '../models/group_editor_mode.dart';
import '../utils/repetition_sequence_format.dart';
import '../validation/business_validation.dart';
import 'group_editor_actions.dart';
import 'group_items_list.dart';
import 'rounds_editor.dart';
import 'type_selector.dart';
import 'timed_group_editor.dart';

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
    final group = controller.group;

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
            TextField(
              controller: controller.nameController,
              autofocus: mode == GroupEditorMode.add,
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
            TypeSelector(value: group.type, onChanged: onTypeChanged),
            const SizedBox(height: 16),
            if (group.type.isTimed)
              TimedGroupEditor(
                controller: controller,
                quick: mode.isQuick,
                hasFollowingGroup: hasFollowingGroup,
                onEditEffort: onEditTimedExercise,
              )
            else ...[
              if (group.type == GroupType.free)
                RoundsEditor(
                  rounds: group.rounds,
                  onChanged: controller.setRounds,
                )
              else
                OutlinedButton.icon(
                  key: const Key('edit-repetition-sequence'),
                  onPressed: onEditRepetitionSequence,
                  icon: const Icon(Icons.format_list_numbered),
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatRepetitionSequenceSummary(group.repetitionSequence),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              GroupItemsList(
                items: group.items,
                repetitionsDefinedByGroup:
                    group.type == GroupType.variableRepetitions,
                onReorder: controller.reorderItems,
                onEdit: onEditItem,
                onDelete: onDeleteItem,
              ),
            ],
            const SizedBox(height: 10),
            GroupEditorActions(
              onAddExercise: onAddExercise,
              onAddRest: onAddRest,
              onSave: onSave,
              actionLabel: mode.actionLabel,
              showItemActions: !group.type.isTimed,
            ),
          ],
        ),
      ),
    );
  }
}
