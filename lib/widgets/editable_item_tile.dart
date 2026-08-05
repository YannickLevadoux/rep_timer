import 'package:flutter/material.dart';

import '../models/training_item.dart';
import '../utils/exercise_icons.dart';

/// Ligne éditable d'un exercice ou d'une pause dans [GroupEditor] :
/// aperçu (icône, nom, valeur), et actions (modifier, supprimer, glisser
/// pour réordonner). Extrait de group_editor.dart pour
/// garder ce dernier concentré sur l'orchestration de l'écran.
class EditableItemTile extends StatelessWidget {
  final TrainingItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int dragIndex;
  final bool repetitionsDefinedByGroup;

  const EditableItemTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.dragIndex,
    this.repetitionsDefinedByGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
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
                  _itemValue(item, repetitionsDefinedByGroup),
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
          Tooltip(
            message: "Réordonner",
            child: ReorderableDragStartListener(
              index: dragIndex,
              child: const SizedBox.square(
                dimension: 48,
                child: Icon(Icons.drag_handle, size: 28),
              ),
            ),
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

  String _itemValue(TrainingItem item, bool repetitionsDefinedByGroup) {
    if (item.type == ItemType.rest) return "${item.duration!.inSeconds} s";
    if (item.isFreeDuration) return "Durée libre";
    if (item.repetitions != null) {
      return repetitionsDefinedByGroup
          ? 'Nombre défini par la suite du groupe'
          : '${item.repetitions} répétitions';
    }
    return "${item.duration?.inSeconds ?? 0} s";
  }
}
