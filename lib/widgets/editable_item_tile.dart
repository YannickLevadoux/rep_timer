import 'package:flutter/material.dart';

import '../models/training_item.dart';
import '../utils/exercise_icons.dart';

/// Tuile d'un exercice ou d'une pause en cours d'édition, sur l'écran
/// "Édition du groupe" : nom + détail (durée/répétitions/durée libre),
/// actions monter/descendre/éditer/supprimer, et poignée de
/// glisser-déposer. Extrait de l'ancien widget interne à
/// `ExerciseGroupCard` (aujourd'hui retiré : l'édition détaillée d'un
/// groupe ne vit plus que sur cet écran dédié) pour rester réutilisable
/// tel quel.
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
          // Ligne 1 : icône + nom + sous-titre (peut se réduire sans jamais déborder)
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
                      item.type == ItemType.rest
                          ? "${item.duration!.inSeconds} s"
                          : item.isFreeDuration
                          ? "Durée libre"
                          : item.repetitions != null
                          ? "${item.repetitions} répétitions"
                          : "${item.duration?.inSeconds ?? 0} s",
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

          // Ligne 2 : actions, jamais contraintes par la largeur du texte au-dessus
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _actionButton(
                context,
                icon: Icons.arrow_upward,
                tooltip: "Monter",
                onPressed: isFirst ? null : onMoveUp,
              ),
              _actionButton(
                context,
                icon: Icons.arrow_downward,
                tooltip: "Descendre",
                onPressed: isLast ? null : onMoveDown,
              ),
              _actionButton(
                context,
                icon: Icons.edit,
                tooltip: "Modifier",
                onPressed: onEdit,
              ),
              _actionButton(
                context,
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

  // Bouton compact : évite que plusieurs boutons côte à côte ne dépassent
  // la largeur de l'écran.
  Widget _actionButton(
    BuildContext context, {
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
