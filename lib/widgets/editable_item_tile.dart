import 'package:flutter/material.dart';

import '../models/training_item.dart';
import '../utils/exercise_icons.dart';

/// Ligne éditable d'un exercice ou d'une pause dans [GroupEditor] :
/// aperçu (icône, nom, valeur), et actions (monter/descendre, modifier,
/// supprimer, glisser pour réordonner). Extrait de group_editor.dart pour
/// garder ce dernier concentré sur l'orchestration de l'écran.
class EditableItemTile extends StatelessWidget {
  final TrainingItem item;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int dragIndex;

  const EditableItemTile({
    super.key,
    required this.item,
    required this.isFirst,
    required this.isLast,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEdit,
    required this.onDelete,
    required this.dragIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
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
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _itemValue(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                index: dragIndex,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.drag_handle, size: 20),
                ),
              ),
            ],
          ),
        ],
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

  String _itemValue(TrainingItem item) {
    if (item.type == ItemType.rest) return "${item.duration!.inSeconds} s";
    if (item.isFreeDuration) return "Durée libre";
    if (item.repetitions != null) return "${item.repetitions} répétitions";
    return "${item.duration?.inSeconds ?? 0} s";
  }
}
