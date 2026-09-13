import 'package:flutter/material.dart';

import '../../models/training_item.dart';
import '../../utils/exercise_icons.dart';
import '../../validation/business_validation.dart';
import '../exercise_icon_picker.dart';
import 'comment_dialog.dart';
import 'tabata_exercise_editor_row.dart';
import 'tabata_exercise_entry.dart';

typedef ExerciseNamePrefillLoader = Future<bool> Function();

Future<List<TrainingItem>?> showTabataExercisesDialog(
  BuildContext context, {
  required List<TrainingItem> initialExercises,
  required Duration effortDuration,
  required ExerciseNamePrefillLoader loadPrefill,
}) => showDialog<List<TrainingItem>>(
  context: context,
  builder: (context) => _TabataExercisesDialog(
    initialExercises: initialExercises,
    effortDuration: effortDuration,
    loadPrefill: loadPrefill,
  ),
);

class _TabataExercisesDialog extends StatefulWidget {
  const _TabataExercisesDialog({
    required this.initialExercises,
    required this.effortDuration,
    required this.loadPrefill,
  });

  final List<TrainingItem> initialExercises;
  final Duration effortDuration;
  final ExerciseNamePrefillLoader loadPrefill;

  @override
  State<_TabataExercisesDialog> createState() => _TabataExercisesDialogState();
}

class _TabataExercisesDialogState extends State<_TabataExercisesDialog> {
  late final List<TabataExerciseEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.initialExercises.map(TabataExerciseEntry.new).toList();
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _add() async {
    if (_entries.length >= BusinessLimits.maximumCount) return;
    final prefill = await widget.loadPrefill();
    if (!mounted) return;
    setState(() {
      _entries.add(
        TabataExerciseEntry(
          TrainingItem(
            type: ItemType.exercise,
            name: prefill ? 'Effort ${_entries.length + 1}' : '',
            duration: widget.effortDuration,
            iconName: defaultExerciseIconName,
          ),
        ),
      );
    });
  }

  void _remove(int index) {
    if (_entries.length <= 1) return;
    setState(() => _entries.removeAt(index).dispose());
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final entry = _entries.removeAt(oldIndex);
      _entries.insert(newIndex, entry);
    });
  }

  Future<void> _editIcon(int index) async {
    final entry = _entries[index];
    final icon = await showExerciseIconPicker(
      context,
      currentIconName: entry.iconName ?? defaultExerciseIconName,
    );
    if (icon != null && mounted) setState(() => entry.iconName = icon);
  }

  Future<void> _editComment(int index) async {
    final entry = _entries[index];
    final comment = await showCommentDialog(
      context,
      initialComment: entry.comment ?? '',
    );
    if (comment != null && mounted) {
      setState(() {
        entry.comment = comment;
        entry.commentError = null;
      });
    }
  }

  void _confirm() {
    var valid = true;
    for (final entry in _entries) {
      if (!entry.validate()) valid = false;
    }
    setState(() {});
    if (!valid) return;
    Navigator.pop(
      context,
      _entries.map((entry) => entry.toItem(widget.effortDuration)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
    contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    title: const Text('Éditer les exercices'),
    content: SizedBox(
      width: 480,
      height: (MediaQuery.sizeOf(context).height * 0.62).clamp(260.0, 500.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: _entries.length,
              onReorderItem: _reorder,
              itemBuilder: (context, index) => TabataExerciseEditorRow(
                key: _entries[index].key,
                index: index,
                entry: _entries[index],
                canDelete: _entries.length > 1,
                onEditIcon: () => _editIcon(index),
                onEditComment: () => _editComment(index),
                onDelete: () => _remove(index),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('add-tabata-cycle'),
              onPressed: _entries.length < BusinessLimits.maximumCount
                  ? _add
                  : null,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un cycle'),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(onPressed: _confirm, child: const Text('Valider')),
    ],
  );
}
