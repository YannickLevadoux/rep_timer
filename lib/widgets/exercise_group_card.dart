import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/training_item.dart';
import '../utils/exercise_group_types.dart';
import '../utils/exercise_icons.dart';
import '../utils/formatters.dart';

class ExerciseGroupCard extends StatelessWidget {
  final ExerciseGroup group;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExerciseGroupCard({
    super.key,
    required this.group,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              group.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exerciseGroupTypeLabel(group.type),
                  style: TextStyle(fontSize: 13, color: outline),
                ),
                Text("Répétitions : ${group.rounds}"),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: "Éditer",
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: "Supprimer",
                  onPressed: onDelete,
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (group.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Aucun exercice"),
            )
          else
            for (var i = 0; i < group.items.length; i++) ...[
              _ExerciseSummary(item: group.items[i]),
              if (i < group.items.length - 1) const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

class _ExerciseSummary extends StatelessWidget {
  final TrainingItem item;

  const _ExerciseSummary({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        item.type == ItemType.exercise
            ? iconForExercise(item.iconName)
            : Icons.timer,
      ),
      title: Text(
        item.type == ItemType.rest ? "Pause" : item.name,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_itemDetail(item)),
    );
  }
}

String _itemDetail(TrainingItem item) {
  if (item.type == ItemType.rest) {
    return formatDuration(item.duration!);
  }
  if (item.isFreeDuration) return "Durée libre";
  if (item.duration != null) return formatDuration(item.duration!);
  return "${item.repetitions} répétitions";
}
