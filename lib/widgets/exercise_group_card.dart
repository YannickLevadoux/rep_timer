import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/group_type.dart';
import '../models/training_item.dart';
import '../utils/exercise_icons.dart';
import '../utils/formatters.dart';
import '../utils/group_summary.dart';
import '../utils/repetition_sequence_format.dart';

class ExerciseGroupCard extends StatelessWidget {
  final ExerciseGroup group;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final ValueChanged<bool> onExpanded;
  final int index;
  final bool expanded;
  final bool hasFollowingGroup;

  const ExerciseGroupCard({
    super.key,
    required this.group,
    required this.onDelete,
    required this.onEdit,
    required this.onExpanded,
    required this.index,
    required this.expanded,
    required this.hasFollowingGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: onExpanded,
        title: Text(
          group.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!group.type.isTimed)
              Text(
                group.type.label,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            Text(
              group.type.isTimed
                  ? formatGroupSummary(
                      group,
                      hasFollowingGroup: hasFollowingGroup,
                    )
                  : group.type == GroupType.variableRepetitions
                  ? formatRepetitionSequenceSummary(group.repetitionSequence)
                  : 'Répétitions : ${group.rounds}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              visualDensity: VisualDensity.compact,
              tooltip: "Éditer le groupe",
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              visualDensity: VisualDensity.compact,
              tooltip: "Supprimer le groupe",
              onPressed: onDelete,
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.drag_handle, size: 20),
              ),
            ),
          ],
        ),
        // children inconditionnel : maintainState vaut false par défaut
        // (on ne le fixe donc plus explicitement à true), ce qui suffit
        // à ExpansionTile pour retirer lui-même ce sous-arbre une fois
        // l'animation de repli terminée. Un rendu conditionnel ici (sur
        // expanded) est redondant avec ce mécanisme et néfaste :
        // onExpansionChanged étant appelé de façon synchrone au tap (pas
        // en fin d'animation), il viderait children dès la frame 0 et
        // l'animation de repli se jouerait sur une boîte déjà vide.
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: group.items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text("Aucun exercice"),
                  )
                : Column(
                    children: group.items
                        .map((item) => _ReadonlyItemRow(item: item))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReadonlyItemRow extends StatelessWidget {
  final TrainingItem item;

  const _ReadonlyItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.type == ItemType.exercise
                ? iconForExercise(item.iconName)
                : Icons.timer,
            size: 18,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.type == ItemType.rest ? "Pause" : item.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(_itemValue(item)),
        ],
      ),
    );
  }

  String _itemValue(TrainingItem item) {
    if (item.type == ItemType.rest) {
      final duration = item.duration;
      return duration == null ? 'Durée invalide' : formatDuration(duration);
    }
    if (item.isFreeDuration) return "Durée libre";
    if (item.repetitions != null) return "${item.repetitions} répétitions";
    return formatDuration(item.duration ?? Duration.zero);
  }
}
