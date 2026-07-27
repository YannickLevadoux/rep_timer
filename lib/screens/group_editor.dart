import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/training_item.dart';
import '../utils/exercise_icons.dart';
import '../utils/snack.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/dialogs/exercise_dialog.dart';
import '../widgets/dialogs/rest_dialog.dart';

class GroupEditor extends StatefulWidget {
  final ExerciseGroup group;
  final bool isNewGroup;

  const GroupEditor({super.key, required this.group, this.isNewGroup = false});

  @override
  State<GroupEditor> createState() => _GroupEditorState();
}

class _GroupEditorState extends State<GroupEditor> {
  late final TextEditingController _nameController;
  late final ExerciseGroup _group;

  @override
  void initState() {
    super.initState();
    _group = ExerciseGroup.fromJson(widget.group.toJson());
    _nameController = TextEditingController(text: _group.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addItem(Future<TrainingItem?> Function() showDialog) async {
    FocusScope.of(context).unfocus();

    final result = await showDialog();
    if (result == null) return;

    setState(() => _group.items.add(result));
  }

  Future<void> _addExercise() {
    return _addItem(
      () => showExerciseDialog(context, defaultName: _group.name),
    );
  }

  Future<void> _addRest() {
    return _addItem(() async {
      final duration = await showRestDialog(context);
      if (duration == null) return null;
      return TrainingItem(
        type: ItemType.rest,
        name: "Pause",
        duration: duration,
      );
    });
  }

  Future<void> _editItem(int index) async {
    FocusScope.of(context).unfocus();

    final item = _group.items[index];
    if (item.type == ItemType.rest) {
      final result = await showRestDialog(context, initial: item.duration);
      if (result == null) return;

      setState(() => item.duration = result);
      return;
    }

    final result = await showExerciseDialog(context, initial: item);
    if (result == null) return;

    setState(() {
      item.name = result.name;
      item.repetitions = result.repetitions;
      item.duration = result.duration;
      item.isFreeDuration = result.isFreeDuration;
      item.comment = result.comment;
      item.iconName = result.iconName;
    });
  }

  Future<void> _deleteItem(int index) async {
    final item = _group.items[index];
    final confirmed = await showConfirmDialog(
      context,
      title: "Supprimer cet élément ?",
      content: 'Supprimer "${item.name}" du groupe ?',
      confirmLabel: "Supprimer",
    );

    if (!confirmed || !mounted) return;

    setState(() => _group.items.removeAt(index));
  }

  void _moveItemUp(int index) {
    if (index == 0) return;

    setState(() {
      final item = _group.items.removeAt(index);
      _group.items.insert(index - 1, item);
    });
  }

  void _moveItemDown(int index) {
    if (index >= _group.items.length - 1) return;

    setState(() {
      final item = _group.items.removeAt(index);
      _group.items.insert(index + 1, item);
    });
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      final item = _group.items.removeAt(oldIndex);
      _group.items.insert(newIndex, item);
    });
  }

  void _saveGroup() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showSnack(context, "Merci de donner un nom au groupe");
      return;
    }

    _group.name = name;
    Navigator.pop(context, ExerciseGroup.fromJson(_group.toJson()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isNewGroup ? "Ajout de groupe" : "Édition du groupe",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              autofocus: widget.isNewGroup,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Nom du groupe",
                hintText: "Ex : Échauffement",
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExerciseGroupType>(
              initialValue: _group.type,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Type du groupe",
              ),
              items: ExerciseGroupType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(exerciseGroupTypeLabel(type)),
                    ),
                  )
                  .toList(),
              onChanged: (type) => setState(() => _group.type = type!),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text("Répétitions"),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: "Moins de répétitions",
                  onPressed: _group.rounds > 1
                      ? () => setState(() => _group.rounds--)
                      : null,
                ),
                Text(
                  '${_group.rounds}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: "Plus de répétitions",
                  onPressed: () => setState(() => _group.rounds++),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _group.items.isEmpty
                  ? const Center(child: Text("Aucun exercice"))
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: _group.items.length,
                      onReorderItem: _reorderItems,
                      itemBuilder: (context, index) {
                        final item = _group.items[index];

                        return _EditableItemTile(
                          key: ValueKey(item),
                          item: item,
                          isFirst: index == 0,
                          isLast: index == _group.items.length - 1,
                          onMoveUp: () => _moveItemUp(index),
                          onMoveDown: () => _moveItemDown(index),
                          onEdit: () => _editItem(index),
                          onDelete: () => _deleteItem(index),
                          dragIndex: index,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.fitness_center),
                  label: const Text("Exercice"),
                ),
                OutlinedButton.icon(
                  onPressed: _addRest,
                  icon: const Icon(Icons.timer),
                  label: const Text("Pause"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveGroup,
                child: const Text("Enregistrer"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableItemTile extends StatelessWidget {
  final TrainingItem item;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int dragIndex;

  const _EditableItemTile({
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
