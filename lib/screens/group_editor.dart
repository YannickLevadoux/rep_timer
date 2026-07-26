import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/group_type.dart';
import '../models/training_item.dart';
import '../utils/snack.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/dialogs/exercise_dialog.dart';
import '../widgets/dialogs/rest_dialog.dart';
import '../widgets/editable_item_tile.dart';

/// Écran dédié à la gestion complète d'un groupe : nom, type,
/// répétitions, et liste des exercices/pauses (ajout, édition,
/// suppression, réorganisation). Ouvert aussi bien pour éditer un groupe
/// existant que pour en créer un nouveau (voir [isNew]).
///
/// Travaille sur une copie locale du groupe reçu : aucune modification
/// n'est reportée sur [group] tant que l'utilisateur n'a pas validé, via
/// le bouton "Enregistrer" ou le choix "Enregistrer" du dialogue de
/// modifications non enregistrées.
///
/// Retourne le groupe modifié via `Navigator.pop`, ou `null` si
/// l'utilisateur abandonne (ou n'a rien modifié). Si [isNew] est vrai,
/// c'est à l'appelant de supprimer le groupe "placeholder" qu'il avait
/// déjà ajouté à sa liste dans ce cas.
class GroupEditorScreen extends StatefulWidget {
  final ExerciseGroup group;
  final bool isNew;

  const GroupEditorScreen({
    super.key,
    required this.group,
    required this.isNew,
  });

  @override
  State<GroupEditorScreen> createState() => _GroupEditorScreenState();
}

class _GroupEditorScreenState extends State<GroupEditorScreen> {
  late final TextEditingController _nameController;

  // Copie profonde : toute modification (nom, type, répétitions,
  // exercices) se fait sur cette copie tant que l'utilisateur n'a pas
  // validé (voir _save), jamais directement sur widget.group.
  late final ExerciseGroup _editable;

  late final String _initialSnapshot;

  @override
  void initState() {
    super.initState();

    _editable = ExerciseGroup.fromJson(widget.group.toJson());
    _nameController = TextEditingController(text: _editable.name);

    // Le titre de l'AppBar affiche le nom en direct : on doit se
    // reconstruire à chaque frappe (même logique que Training Editor).
    _nameController.addListener(_onNameChanged);

    _initialSnapshot = _currentSnapshot();
  }

  void _onNameChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  // Représentation canonique de l'état actuel de l'écran, utilisée pour
  // détecter les modifications non enregistrées (même principe que
  // Training Editor, réutilisant directement toJson()).
  String _currentSnapshot() {
    final snapshot = _editable.toJson();
    snapshot['name'] = _nameController.text.trim();
    return jsonEncode(snapshot);
  }

  bool get _hasUnsavedChanges => _currentSnapshot() != _initialSnapshot;

  void _save() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      showSnack(context, "Merci de donner un nom au groupe");
      return;
    }

    _editable.name = name;
    Navigator.pop(context, _editable);
  }

  // Gère le bouton Retour : sortie directe si rien n'a changé, sinon
  // propose Enregistrer / Abandonner les modifications / Annuler (même
  // dialogue que Training Editor).
  Future<void> _handleBackPressed() async {
    if (!_hasUnsavedChanges) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final choice = await showUnsavedChangesDialog(context);

    switch (choice) {
      case 'save':
        _save();
        break;
      case 'discard':
        if (mounted) Navigator.pop(context);
        break;
      case 'cancel':
      default:
        break;
    }
  }

  void _updateType(GroupType? type) {
    if (type == null) return;
    setState(() => _editable.type = type);
  }

  void _updateRounds(int rounds) {
    if (rounds < 1) return;
    setState(() => _editable.rounds = rounds);
  }

  void _moveItemUp(int index) {
    if (index == 0) return;
    setState(() {
      final item = _editable.items.removeAt(index);
      _editable.items.insert(index - 1, item);
    });
  }

  void _moveItemDown(int index) {
    if (index >= _editable.items.length - 1) return;
    setState(() {
      final item = _editable.items.removeAt(index);
      _editable.items.insert(index + 1, item);
    });
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      final item = _editable.items.removeAt(oldIndex);
      _editable.items.insert(newIndex, item);
    });
  }

  Future<void> _confirmDeleteItem(int index) async {
    final item = _editable.items[index];
    final isRest = item.type == ItemType.rest;

    await confirmAndDelete(
      context,
      title: isRest ? "Supprimer la pause ?" : "Supprimer l'exercice ?",
      content: isRest
          ? "Cette action est irréversible. Supprimer cette pause ?"
          : 'Cette action est irréversible. Supprimer "${item.name}" ?',
      onDelete: () async {
        setState(() => _editable.items.removeAt(index));
      },
    );
  }

  // Modification d'un exercice ou d'une pause existant(e) — logique
  // inchangée par rapport à l'ancien Training Editor.
  Future<void> _editItem(int index) async {
    FocusScope.of(context).unfocus();

    final item = _editable.items[index];

    if (item.type == ItemType.rest) {
      final result = await showRestDialog(context, initial: item.duration);

      if (result != null) {
        setState(() => item.duration = result);
      }
      return;
    }

    final result = await showExerciseDialog(context, initial: item);

    if (result != null) {
      setState(() {
        item.name = result.name;
        item.repetitions = result.repetitions;
        item.duration = result.duration;
        item.isFreeDuration = result.isFreeDuration;
        item.comment = result.comment;
        item.iconName = result.iconName;
      });
    }
  }

  Future<void> _addItem(Future<TrainingItem?> Function() showItemDialog) async {
    FocusScope.of(context).unfocus();

    final result = await showItemDialog();

    if (result != null) {
      setState(() => _editable.items.add(result));
    }
  }

  Future<void> _addExercise() {
    return _addItem(
      () => showExerciseDialog(context, defaultName: _editable.name),
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

  @override
  Widget build(BuildContext context) {
    final displayedName = _nameController.text.trim();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPressed();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            displayedName.isEmpty ? "Nouveau groupe" : displayedName,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Nom du groupe",
                  hintText: "Ex : Échauffement",
                ),
              ),

              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Type de groupe",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 4),
              DropdownButton<GroupType>(
                value: _editable.type,
                isExpanded: true,
                items: GroupType.values
                    .map(
                      (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                    )
                    .toList(),
                onChanged: _updateType,
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Répétitions : "),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: "Moins de répétitions",
                    visualDensity: VisualDensity.compact,
                    onPressed: _editable.rounds > 1
                        ? () => _updateRounds(_editable.rounds - 1)
                        : null,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_editable.rounds}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: "Plus de répétitions",
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _updateRounds(_editable.rounds + 1),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Expanded(
                child: _editable.items.isEmpty
                    ? const Center(child: Text("Aucun exercice"))
                    : ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        itemCount: _editable.items.length,
                        onReorderItem: _reorderItems,
                        itemBuilder: (context, index) {
                          final item = _editable.items[index];

                          return EditableItemTile(
                            // La clé doit suivre l'item (identité), pas sa
                            // position.
                            key: ValueKey(item),
                            item: item,
                            isFirst: index == 0,
                            isLast: index == _editable.items.length - 1,
                            onMoveUp: () => _moveItemUp(index),
                            onMoveDown: () => _moveItemDown(index),
                            onEdit: () => _editItem(index),
                            onDelete: () => _confirmDeleteItem(index),
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
                  onPressed: _save,
                  child: const Text("Enregistrer"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
