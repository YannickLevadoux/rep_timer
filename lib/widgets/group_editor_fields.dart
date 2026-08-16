import 'package:flutter/material.dart';

import '../controllers/group_editor_controller.dart';
import '../models/group_editor_mode.dart';
import '../models/group_type.dart';
import '../utils/repetition_sequence_format.dart';
import 'group_editor_actions.dart';
import 'group_items_list.dart';
import 'rounds_editor.dart';
import 'timed_group_editor.dart';

class GroupEditorFields extends StatelessWidget {
  const GroupEditorFields({
    super.key,
    required this.controller,
    required this.mode,
    required this.onAddExercise,
    required this.onAddRest,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onSave,
    required this.onEditRepetitionSequence,
    required this.onEditTimedExercise,
    required this.hasFollowingGroup,
    required this.isSubmitting,
  });

  final GroupEditorController controller;
  final GroupEditorMode mode;
  final VoidCallback onAddExercise;
  final VoidCallback onAddRest;
  final ValueChanged<int> onEditItem;
  final ValueChanged<int> onDeleteItem;
  final VoidCallback onSave;
  final VoidCallback onEditRepetitionSequence;
  final VoidCallback onEditTimedExercise;
  final bool hasFollowingGroup;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final group = controller.group;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (group.type.isTimed)
          TimedGroupEditor(
            controller: controller,
            quick: mode.isQuick,
            hasFollowingGroup: hasFollowingGroup,
            onEditEffort: onEditTimedExercise,
          )
        else ...[
          if (group.type == GroupType.free)
            RoundsEditor(rounds: group.rounds, onChanged: controller.setRounds)
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
          actionLabel: mode.isQuick && isSubmitting
              ? 'Préparation…'
              : mode.actionLabel,
          showItemActions: !group.type.isTimed,
          enabled: !isSubmitting,
        ),
      ],
    );
  }
}
