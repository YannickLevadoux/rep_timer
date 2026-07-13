import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/training_item.dart';
import '../utils/exercise_icons.dart';

class ExerciseGroupCard extends StatelessWidget {
  final ExerciseGroup group;

  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onAddExercise;
  final VoidCallback onAddRest;
  final ValueChanged<bool> onExpanded;
  final ValueChanged<int> onRoundsChanged;

  // Réordonnancement / actions sur les exercices d'un groupe
  final void Function(int oldIndex, int newIndex) onReorderItems;
  final void Function(int itemIndex) onMoveItemUp;
  final void Function(int itemIndex) onMoveItemDown;
  final void Function(int itemIndex) onEditItem;
  final void Function(int itemIndex) onDeleteItem;

  final int index;

  const ExerciseGroupCard({
    super.key,
    required this.group,
    required this.onDelete,
    required this.onRename,
    required this.onAddExercise,
    required this.onAddRest,
    required this.onExpanded,
    required this.onRoundsChanged,
    required this.onReorderItems,
    required this.onMoveItemUp,
    required this.onMoveItemDown,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),

      child: ExpansionTile(
        maintainState: true,
        initiallyExpanded: group.expanded,
        onExpansionChanged: onExpanded,

        title: Text(
          group.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        subtitle: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text("Répétitions : "),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: "Moins de répétitions",
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              onPressed: group.rounds > 1
                  ? () => onRoundsChanged(group.rounds - 1)
                  : null,
            ),
            const SizedBox(width: 4),
            Text(
              '${group.rounds}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: "Plus de répétitions",
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              onPressed: () => onRoundsChanged(group.rounds + 1),
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
              onPressed: onRename,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
            ),

            // Poignée de drag du GROUPE (inchangé)
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.drag_handle, size: 20),
              ),
            ),
          ],
        ),

        children: [
          // Zone "dépliée" du groupe : fond légèrement différent du header
          // de la Card, pour bien distinguer visuellement groupe vs exercices.
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: group.items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text("Aucun exercice"),
                  )
                : ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: group.items.length,
                    onReorder: onReorderItems,
                    itemBuilder: (context, itemIndex) {
                      final item = group.items[itemIndex];

                      return _ItemTile(
                        // La clé doit suivre l'item (identité), pas sa position
                        key: ValueKey(item),
                        item: item,
                        isFirst: itemIndex == 0,
                        isLast: itemIndex == group.items.length - 1,
                        onMoveUp: () => onMoveItemUp(itemIndex),
                        onMoveDown: () => onMoveItemDown(itemIndex),
                        onEdit: () => onEditItem(itemIndex),
                        onDelete: () => onDeleteItem(itemIndex),
                        dragIndex: itemIndex,
                      );
                    },
                  ),
          ),

          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: onAddExercise,
                        icon: const Icon(Icons.fitness_center),
                        label: const Text("Exercice"),
                      ),
                      OutlinedButton.icon(
                        onPressed: onAddRest,
                        icon: const Icon(Icons.timer),
                        label: const Text("Pause"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tuile d'un exercice ou d'une pause à l'intérieur d'un groupe.
/// Affiche : nom + ↑ ↓ ✏️ 🗑️ + poignée de drag.
class _ItemTile extends StatelessWidget {
  final TrainingItem item;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int dragIndex;

  const _ItemTile({
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

  // Bouton compact : évite que 5 boutons côte à côte ne dépassent la largeur de l'écran
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
