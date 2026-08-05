import 'package:flutter/material.dart';

import '../controllers/group_editor_controller.dart';
import '../models/exercise_group.dart';
import '../models/training_item.dart';
import '../models/group_type.dart';
import '../services/app_settings_storage.dart';
import '../utils/editor_back_handler.dart';
import '../utils/snack.dart';
import '../utils/validation_messages.dart';
import '../validation/business_validation.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/dialogs/exercise_dialog.dart';
import '../widgets/dialogs/group_editor_settings_dialog.dart';
import '../widgets/dialogs/rest_dialog.dart';
import '../widgets/dialogs/repetition_sequence_dialog.dart';
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
  String? _nameError;

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
        repetitionsDefinedByGroup:
            _controller.group.type == GroupType.variableRepetitions,
        repetitionFallback: _repetitionFallback,
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
      final duration = await showRestDialog(
        context,
        initial: item.duration ?? Duration.zero,
      );
      if (duration != null) _controller.updateRest(index, duration);
      return;
    }

    final result = await showExerciseDialog(
      context,
      initial: item,
      repetitionsDefinedByGroup:
          _controller.group.type == GroupType.variableRepetitions,
      repetitionFallback: _repetitionFallback,
    );
    if (result != null) _controller.updateExercise(index, result);
  }

  int get _repetitionFallback =>
      _controller.group.repetitionSequence.firstOrNull ??
      BusinessLimits.minimumCount;

  Future<void> _editRepetitionSequence() async {
    FocusScope.of(context).unfocus();
    final result = await showRepetitionSequenceDialog(
      context,
      initialValues: _controller.group.repetitionSequence,
      fallbackValue: _repetitionFallback,
    );
    if (result != null) _controller.setRepetitionSequence(result);
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
    final group = _controller.save();
    final issues = BusinessValidation.validateGroup(group);
    final nameIssue = issues
        .where((issue) => issue.field == BusinessField.groupName)
        .firstOrNull;
    if (issues.isNotEmpty) {
      setState(() {
        _nameError = nameIssue == null ? null : validationMessage(nameIssue);
      });
      if (nameIssue != null) {
        showSnack(context, "Merci de donner un nom au groupe");
      } else {
        showSnack(context, validationMessage(issues.first));
      }
      return;
    }
    Navigator.pop(context, group);
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
          onEditRepetitionSequence: _editRepetitionSequence,
          nameError: _nameError,
        ),
      ),
    );
  }
}
