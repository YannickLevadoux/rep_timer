import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/training_item.dart';
import '../services/app_settings_storage.dart';
import '../utils/snack.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/dialogs/exercise_dialog.dart';
import '../widgets/dialogs/group_editor_settings_dialog.dart';
import '../widgets/dialogs/rest_dialog.dart';
import '../widgets/group_editor_actions.dart';
import '../widgets/group_items_list.dart';
import '../widgets/rounds_editor.dart';
import '../widgets/type_selector.dart';

/// Écran d'édition d'un groupe d'exercices (création ou modification) :
/// nom, type, nombre de répétitions, et liste ordonnée des
/// exercices/pauses qui le composent.
///
/// La présentation de la liste des items vit dans [GroupItemsList] (qui
/// s'appuie elle-même sur `EditableItemTile`), et les blocs "Type du
/// groupe" / "Répétitions" dans leurs propres widgets ([TypeSelector],
/// [RoundsEditor]) : ce fichier ne s'occupe que de l'orchestration (état
/// du groupe en cours d'édition, actions sur ses items).
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
  late final String _initialSnapshot;
  final AppSettingsStorage _settingsStorage = AppSettingsStorage();

  @override
  void initState() {
    super.initState();
    // Copie profonde (voir ExerciseGroup.copyWith) : les items ne sont
    // jamais partagés avec l'original tant que "Enregistrer" n'a pas été
    // pressé.
    _group = widget.group.copyWith();
    _nameController = TextEditingController(text: _group.name);
    _initialSnapshot = _currentSnapshot();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _currentSnapshot() {
    return jsonEncode({
      ..._group.toJson(),
      'name': _nameController.text.trim(),
    });
  }

  bool get _hasUnsavedChanges => _currentSnapshot() != _initialSnapshot;

  // Aligné sur le comportement de TrainingEditor : mêmes 3 choix
  // (Enregistrer / Abandonner les modifications / Annuler), pour une
  // cohérence UX entre les deux écrans d'édition de l'application.
  Future<void> _handleBackPressed() async {
    if (!_hasUnsavedChanges) {
      Navigator.pop(context);
      return;
    }

    final choice = await showUnsavedChangesDialog(context);

    switch (choice) {
      case 'save':
        _saveGroup();
        break;
      case 'discard':
        if (mounted) Navigator.pop(context);
        break;
      case 'cancel':
      default:
        break;
    }
  }

  Future<void> _addItem(Future<TrainingItem?> Function() showDialog) async {
    FocusScope.of(context).unfocus();

    final result = await showDialog();
    if (result == null) return;

    setState(() => _group.items.add(result));
  }

  // Le réglage est relu à chaque ajout (plutôt que mis en cache dans
  // l'état de l'écran) : s'il vient d'être modifié via le dialogue de
  // réglages, la prochaine création d'exercice en tient compte
  // immédiatement, sans qu'il soit nécessaire de rouvrir l'écran.
  Future<void> _addExercise() async {
    final prefill = await _settingsStorage.loadPrefillExerciseName();
    if (!mounted) return;

    await _addItem(
      () => showExerciseDialog(
        context,
        defaultName: prefill ? _nameController.text.trim() : '',
      ),
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
      title: item.type == ItemType.rest
          ? "Supprimer la pause ?"
          : "Supprimer l'exercice ?",
      content: 'Supprimer "${item.name}" du groupe ?',
      confirmLabel: "Supprimer",
    );

    if (!confirmed || !mounted) return;

    setState(() => _group.items.removeAt(index));
  }

  // Factorise "monter" (delta -1) et "descendre" (delta +1) : même
  // opération de déplacement, seul le sens change.
  void _moveItem(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _group.items.length) return;

    setState(() {
      final item = _group.items.removeAt(index);
      _group.items.insert(target, item);
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
    Navigator.pop(context, _group);
  }

  Future<void> _openSettings() => showGroupEditorSettingsDialog(context);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPressed();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isNewGroup ? "Ajout de groupe" : "Édition du groupe",
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: "Paramètres",
              onPressed: _openSettings,
            ),
          ],
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
              TypeSelector(
                value: _group.type,
                onChanged: (type) => setState(() => _group.type = type),
              ),
              const SizedBox(height: 16),
              RoundsEditor(
                rounds: _group.rounds,
                onChanged: (rounds) => setState(() => _group.rounds = rounds),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GroupItemsList(
                  items: _group.items,
                  onReorder: _reorderItems,
                  onMoveUp: (index) => _moveItem(index, -1),
                  onMoveDown: (index) => _moveItem(index, 1),
                  onEdit: _editItem,
                  onDelete: _deleteItem,
                ),
              ),
              const SizedBox(height: 10),
              GroupEditorActions(
                onAddExercise: _addExercise,
                onAddRest: _addRest,
                onSave: _saveGroup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
