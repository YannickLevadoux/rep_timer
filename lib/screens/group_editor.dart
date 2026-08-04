import 'package:flutter/material.dart';

import '../controllers/group_editor_controller.dart';
import '../models/exercise_group.dart';
import '../models/training_item.dart';
import '../services/app_settings_storage.dart';
import '../utils/editor_back_handler.dart';
import '../utils/snack.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/dialogs/exercise_dialog.dart';
import '../widgets/dialogs/group_editor_settings_dialog.dart';
import '../widgets/dialogs/rest_dialog.dart';
import '../widgets/group_editor_view.dart';

class GroupEditor extends StatefulWidget {
  const GroupEditor({super.key, required this.group, this.isNewGroup = false});

  final ExerciseGroup group;
  final bool isNewGroup;

  @override
  State<GroupEditor> createState() => _GroupEditorState();
}

class _GroupEditorState extends State<GroupEditor> {
  final AppSettingsStorage _settingsStorage = AppSettingsStorage();
  late final GroupEditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GroupEditorController(widget.group);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBackPressed() => handleEditorBack(
    context,
    hasUnsavedChanges: _controller.hasUnsavedChanges,
    onSave: _saveGroup,
  );

  Future<void> _addItem(Future<TrainingItem?> Function() openDialog) async {
    FocusScope.of(context).unfocus();
    final result = await openDialog();
    if (result != null) _controller.addItem(result);
  }

  Future<void> _addExercise() async {
    final prefill = await _settingsStorage.loadPrefillExerciseName();
    if (!mounted) return;

    await _addItem(
      () => showExerciseDialog(
        context,
        defaultName: prefill ? _controller.name : '',
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
    final item = _controller.group.items[index];

    if (item.type == ItemType.rest) {
      final duration = await showRestDialog(context, initial: item.duration);
      if (duration != null) _controller.updateRest(index, duration);
      return;
    }

    final result = await showExerciseDialog(context, initial: item);
    if (result != null) _controller.updateExercise(index, result);
  }

  Future<void> _deleteItem(int index) async {
    final item = _controller.group.items[index];
    final confirmed = await showConfirmDialog(
      context,
      title: item.type == ItemType.rest
          ? "Supprimer la pause ?"
          : "Supprimer l'exercice ?",
      content: 'Supprimer "${item.name}" du groupe ?',
      confirmLabel: "Supprimer",
    );
    if (confirmed && mounted) _controller.removeItem(index);
  }

  void _saveGroup() {
    if (_controller.name.isEmpty) {
      showSnack(context, "Merci de donner un nom au groupe");
      return;
    }
    Navigator.pop(context, _controller.save());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) await _handleBackPressed();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => GroupEditorView(
          controller: _controller,
          isNewGroup: widget.isNewGroup,
          onOpenSettings: () => showGroupEditorSettingsDialog(context),
          onAddExercise: _addExercise,
          onAddRest: _addRest,
          onEditItem: _editItem,
          onDeleteItem: _deleteItem,
          onSave: _saveGroup,
        ),
      ),
    );
  }
}
