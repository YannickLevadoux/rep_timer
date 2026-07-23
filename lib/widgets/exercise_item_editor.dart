import 'package:flutter/material.dart';

import '../models/training_item.dart';
import '../utils/exercise_icons.dart';
import '../utils/formatters.dart';

class ExerciseItemEditor extends StatelessWidget {
  final List<TrainingItem> items;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onMoveUp;
  final void Function(int index) onMoveDown;
  final void Function(int index) onEdit;
  final void Function(int index) onDelete;

  const ExerciseItemEditor({
    super.key,
    required this.items,
    required this.onReorder,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("Aucun exercice"),
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      onReorderItem: onReorder,
      itemBuilder: (context, index) {
        return _ItemTile(
          key: ValueKey(items[index]),
          item: items[index],
          index: index,
          isFirst: index == 0,
          isLast: index == items.length - 1,
          onMoveUp: () => onMoveUp(index),
          onMoveDown: () => onMoveDown(index),
          onEdit: () => onEdit(index),
          onDelete: () => onDelete(index),
        );
      },
    );
  }
}

class _ItemTile extends StatelessWidget {
  final TrainingItem item;
  final int index;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item.type == ItemType.exercise
                      ? iconForExercise(item.iconName)
                      : Icons.timer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.type == ItemType.rest ? "Pause" : item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _itemDetail(item),
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionButton(
                  icon: Icons.arrow_upward,
                  tooltip: "Monter",
                  onPressed: isFirst ? null : onMoveUp,
                ),
                _actionButton(
                  icon: Icons.arrow_downward,
                  tooltip: "Descendre",
                  onPressed: isLast ? null : onMoveDown,
                ),
                _actionButton(
                  icon: Icons.edit,
                  tooltip: "Modifier",
                  onPressed: onEdit,
                ),
                _actionButton(
                  icon: Icons.delete,
                  tooltip: "Supprimer",
                  onPressed: onDelete,
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.drag_handle, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}

String _itemDetail(TrainingItem item) {
  if (item.type == ItemType.rest) return formatDuration(item.duration!);
  if (item.isFreeDuration) return "Durée libre";
  if (item.duration != null) return formatDuration(item.duration!);
  return "${item.repetitions} répétitions";
}
