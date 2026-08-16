import 'package:flutter/material.dart';

import '../controllers/group_editor_controller.dart';
import '../models/exercise_group.dart';
import '../models/group_editor_mode.dart';
import '../models/group_type.dart';
import '../utils/editor_back_handler.dart';
import '../utils/snack.dart';
import '../utils/validation_messages.dart';
import '../validation/business_validation.dart';
import '../widgets/dialogs/group_editor_settings_dialog.dart';
import '../widgets/dialogs/quick_session_exit_dialog.dart';
import '../widgets/group_editor_view.dart';
import 'group_editor_dialogs.dart';

class GroupEditor extends StatefulWidget {
  const GroupEditor({
    super.key,
    required this.group,
    this.isNewGroup = false,
    this.mode,
    this.hasFollowingGroup = false,
    this.onSubmit,
  });

  final ExerciseGroup group;
  final bool isNewGroup;
  final GroupEditorMode? mode;
  final bool hasFollowingGroup;
  final Future<void> Function(ExerciseGroup group)? onSubmit;

  GroupEditorMode get effectiveMode =>
      mode ?? (isNewGroup ? GroupEditorMode.add : GroupEditorMode.edit);

  @override
  State<GroupEditor> createState() => _GroupEditorState();
}

class _GroupEditorState extends State<GroupEditor> {
  late final GroupEditorController _controller;
  late final GroupEditorDialogs _dialogs;
  String? _nameError;
  bool _showQuickWarning = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = GroupEditorController(
      widget.group,
      requiresInitialTypeSelection:
          widget.effectiveMode.requiresInitialTypeSelection,
    );
    _dialogs = GroupEditorDialogs(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBackPressed() async {
    if (!widget.effectiveMode.isQuick) {
      return handleEditorBack(
        context,
        hasUnsavedChanges: _controller.hasUnsavedChanges,
        onSave: _saveGroup,
      );
    }
    if (!_controller.hasUnsavedChanges) {
      Navigator.pop(context);
      return;
    }
    FocusScope.of(context).unfocus();
    final shouldLeave = await showQuickSessionExitDialog(context);
    if (shouldLeave && mounted) Navigator.pop(context);
  }

  Future<void> _changeType(GroupType type) async {
    await _dialogs.changeType(context, type);
    if (mounted) setState(() {});
  }

  Future<void> _saveGroup() async {
    if (_isSubmitting) return;
    final group = _controller.saveIfSelected();
    if (group == null) {
      showSnack(context, 'Sélectionnez un type de groupe.');
      return;
    }
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
    setState(() => _nameError = null);
    if (widget.onSubmit != null) {
      setState(() => _isSubmitting = true);
      try {
        await widget.onSubmit!(group);
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _showQuickWarning = true;
          });
        }
      }
    } else if (mounted) {
      Navigator.pop(context, group);
    }
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
          mode: widget.effectiveMode,
          onOpenSettings: () => showGroupEditorSettingsDialog(context),
          onAddExercise: () => _dialogs.addExercise(context),
          onAddRest: () => _dialogs.addRest(context),
          onEditItem: (index) => _dialogs.editItem(context, index),
          onDeleteItem: (index) => _dialogs.deleteItem(context, index),
          onSave: _saveGroup,
          onEditRepetitionSequence: () =>
              _dialogs.editRepetitionSequence(context),
          onTypeChanged: _changeType,
          onEditTimedExercise: () => _dialogs.editTimedExercise(context),
          hasFollowingGroup: widget.hasFollowingGroup,
          showQuickWarning: _showQuickWarning,
          onDismissQuickWarning: () =>
              setState(() => _showQuickWarning = false),
          isSubmitting: _isSubmitting,
          nameError: _nameError,
        ),
      ),
    );
  }
}
