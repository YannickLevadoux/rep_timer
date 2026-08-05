import 'package:flutter/material.dart';

import '../models/training_item.dart';
import 'editable_item_tile.dart';

/// Liste réordonnable des exercices/pauses d'un groupe (via
/// [EditableItemTile]), avec repli sur un message si le groupe est vide.
/// Isolé de [GroupEditor] pour que ce dernier reste concentré sur
/// l'orchestration (actions CRUD, sauvegarde) plutôt que sur la
/// présentation de la liste elle-même.
class GroupItemsList extends StatelessWidget {
  final List<TrainingItem> items;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onEdit;
  final void Function(int index) onDelete;
  final bool repetitionsDefinedByGroup;

  const GroupItemsList({
    super.key,
    required this.items,
    required this.onReorder,
    required this.onEdit,
    required this.onDelete,
    this.repetitionsDefinedByGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text("Aucun exercice"));
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: items.length,
      onReorderItem: onReorder,
      itemBuilder: (context, index) {
        final item = items[index];

        return EditableItemTile(
          key: ValueKey(item),
          item: item,
          onEdit: () => onEdit(index),
          onDelete: () => onDelete(index),
          dragIndex: index,
          repetitionsDefinedByGroup: repetitionsDefinedByGroup,
        );
      },
    );
  }
}
