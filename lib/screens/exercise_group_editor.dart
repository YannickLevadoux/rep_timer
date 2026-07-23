import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/training_item.dart';
import '../utils/exercise_group_types.dart';
import '../utils/snack.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/dialogs/exercise_dialog.dart';
import '../widgets/dialogs/rest_dialog.dart';
import '../widgets/exercise_item_editor.dart';

class ExerciseGroupEditorScreen extends StatefulWidget {
  final ExerciseGroup? group;

  const ExerciseGroupEditorScreen({super.key, this.group});

  @override
  State<ExerciseGroupEditorScreen> createState() =>
      _ExerciseGroupEditorScreenState();
}

class _ExerciseGroupEditorScreenState extends State<ExerciseGroupEditorScreen> {
  late final ExerciseGroup _group;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _group = widget.group != null
        ? ExerciseGroup.fromJson(widget.group!.toJson())
        : ExerciseGroup(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: "",
            items: [],
          );
    _nameController = TextEditingController(text: _group.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _moveItemUp(int index) {
    setState(() {
      final item = _group.items.removeAt(index);
      _group.items.insert(index - 1, item);
    });
  }

  void _moveItemDown(int index) {
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

  Future<void> _deleteItem(int index) async {
    final item = _group.items[index];
    final isRest = item.type == ItemType.rest;
    final confirmed = await showConfirmDialog(
      context,
      title: isRest ? "Supprimer la pause ?" : "Supprimer l'exercice ?",
      content: isRest
          ? "Cette pause sera supprimée du groupe."
          : 'L\'exercice "${item.name}" sera supprimé du groupe.',
      confirmLabel: "Supprimer",
    );

    if (!confirmed || !mounted) return;
    setState(() => _group.items.removeAt(index));
  }

  Future<void> _editItem(int index) async {
    FocusScope.of(context).unfocus();
    final item = _group.items[index];

    if (item.type == ItemType.rest) {
      final duration = await showRestDialog(context, initial: item.duration);
      if (!mounted || duration == null) return;
      setState(() => item.duration = duration);
      return;
    }

    final result = await showExerciseDialog(context, initial: item);
    if (!mounted || result == null) return;

    setState(() => _group.items[index] = result);
  }

  Future<void> _addExercise() async {
    FocusScope.of(context).unfocus();
    final result = await showExerciseDialog(
      context,
      defaultName: _nameController.text.trim(),
    );
    if (!mounted || result == null) return;
    setState(() => _group.items.add(result));
  }

  Future<void> _addRest() async {
    FocusScope.of(context).unfocus();
    final duration = await showRestDialog(context);
    if (!mounted || duration == null) return;

    setState(() {
      _group.items.add(
        TrainingItem(type: ItemType.rest, name: "Pause", duration: duration),
      );
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showSnack(context, "Merci de donner un nom au groupe");
      return;
    }

    _group.name = name;
    Navigator.pop(context, _group);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.group == null ? "Ajout de groupe" : "Édition du groupe",
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Nom du groupe",
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
                  _RoundsEditor(
                    rounds: _group.rounds,
                    onChanged: (rounds) =>
                        setState(() => _group.rounds = rounds),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Exercices",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ExerciseItemEditor(
                    items: _group.items,
                    onReorder: _reorderItems,
                    onMoveUp: _moveItemUp,
                    onMoveDown: _moveItemDown,
                    onEdit: _editItem,
                    onDelete: _deleteItem,
                  ),
                  const SizedBox(height: 12),
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text("Enregistrer"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundsEditor extends StatelessWidget {
  final int rounds;
  final ValueChanged<int> onChanged;

  const _RoundsEditor({required this.rounds, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Text("Répétitions")),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          tooltip: "Moins de répétitions",
          onPressed: rounds > 1 ? () => onChanged(rounds - 1) : null,
        ),
        Text("$rounds", style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          tooltip: "Plus de répétitions",
          onPressed: () => onChanged(rounds + 1),
        ),
      ],
    );
  }
}
