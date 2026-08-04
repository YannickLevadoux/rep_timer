import 'package:flutter/material.dart';

import '../controllers/training_editor_controller.dart';
import '../models/exercise_group.dart';
import '../models/training.dart';
import '../services/json_prefs_storage.dart';
import '../services/training_storage.dart';
import '../utils/editor_back_handler.dart';
import '../utils/snack.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/training_editor_view.dart';
import 'group_editor.dart';

class TrainingEditor extends StatefulWidget {
  const TrainingEditor({super.key, this.training});

  final Training? training;

  @override
  State<TrainingEditor> createState() => _TrainingEditorState();
}

class _TrainingEditorState extends State<TrainingEditor> {
  final TrainingStorage _storage = TrainingStorage();
  late final TrainingEditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TrainingEditorController(widget.training);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveTraining() async {
    if (_controller.name.isEmpty) {
      showSnack(context, "Merci de donner un nom à la séance");
      return;
    }
    if (_controller.groups.isEmpty) {
      showSnack(context, "Ajoute au moins un groupe d'exercices");
      return;
    }

    _controller.setSaving(true);
    try {
      await _storage.addOrUpdateTraining(_controller.buildTraining());
    } on StorageMutationBlockedException {
      if (!mounted) return;
      _controller.setSaving(false);
      showSnack(
        context,
        "Enregistrement impossible : certaines séances n'ont pas pu être "
        "lues. Les données existantes ont été conservées.",
      );
      return;
    }
    if (!mounted) return;

    _controller.setSaving(false);
    showSnack(context, "Séance enregistrée");
    Navigator.pop(context, true);
  }

  Future<void> _handleBackPressed() => handleEditorBack(
    context,
    hasUnsavedChanges: _controller.hasUnsavedChanges,
    onSave: _saveTraining,
  );

  Future<void> _confirmDeleteTraining() async {
    FocusScope.of(context).unfocus();
    final training = widget.training;
    if (training == null) return;

    try {
      final deleted = await confirmAndDelete(
        context,
        title: "Supprimer la séance ?",
        content:
            'Cette action est irréversible. Supprimer "${training.name}" ?',
        onDelete: () => _storage.deleteTraining(training.id),
      );
      if (deleted && mounted) Navigator.pop(context, true);
    } on StorageMutationBlockedException {
      if (!mounted) return;
      showSnack(
        context,
        "Suppression impossible : certaines séances n'ont pas pu être lues.",
      );
    }
  }

  Future<void> _addGroup() async {
    FocusScope.of(context).unfocus();
    final group = await Navigator.push<ExerciseGroup>(
      context,
      MaterialPageRoute(
        builder: (_) => GroupEditor(
          group: ExerciseGroup(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: "",
            items: [],
          ),
          isNewGroup: true,
        ),
      ),
    );
    if (group == null || !mounted) return;

    _controller.addGroup(group);
    _controller.scrollGroupsListToEnd();
  }

  Future<void> _editGroup(int index) async {
    FocusScope.of(context).unfocus();
    final editedGroup = await Navigator.push<ExerciseGroup>(
      context,
      MaterialPageRoute(
        builder: (_) => GroupEditor(group: _controller.groups[index]),
      ),
    );
    if (editedGroup != null && mounted) {
      _controller.replaceGroup(index, editedGroup);
    }
  }

  Future<void> _deleteGroup(int index) async {
    final group = _controller.groups[index];
    final confirmed = await showConfirmDialog(
      context,
      title: "Supprimer le groupe ?",
      content: 'Supprimer "${group.name}" de la séance ?',
      confirmLabel: "Supprimer",
    );
    if (confirmed && mounted) _controller.removeGroup(index);
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
        builder: (context, _) => TrainingEditorView(
          controller: _controller,
          canDeleteTraining: widget.training != null,
          onDeleteTraining: _confirmDeleteTraining,
          onAddGroup: _addGroup,
          onEditGroup: _editGroup,
          onDeleteGroup: _deleteGroup,
          onSave: _saveTraining,
        ),
      ),
    );
  }
}
