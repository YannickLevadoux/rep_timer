import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/training.dart';
import '../services/json_prefs_storage.dart';
import '../services/training_storage.dart';
import '../utils/snack.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/exercise_group_card.dart';
import 'group_editor.dart';

class TrainingEditor extends StatefulWidget {
  final Training? training;

  const TrainingEditor({super.key, this.training});

  @override
  State<TrainingEditor> createState() => _TrainingEditorState();
}

class _TrainingEditorState extends State<TrainingEditor> {
  final TextEditingController _nameController = TextEditingController();
  final ScrollController _groupsScrollController = ScrollController();
  final TrainingStorage _storage = TrainingStorage();
  final List<ExerciseGroup> groups = [];

  // État de présentation propre à cette ouverture de l'écran. Il ne fait
  // volontairement partie ni des groupes édités, ni de leur snapshot JSON.
  final Set<String> _expandedGroupIds = {};

  late final String _initialSnapshot;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final existing = widget.training;
    if (existing != null) {
      _nameController.text = existing.name;
      // Copie profonde (voir ExerciseGroup.copyWith) : les groupes édités
      // ici ne doivent jamais partager leurs items avec la séance
      // d'origine tant que "Enregistrer" n'a pas été pressé.
      groups.addAll(existing.groups.map((group) => group.copyWith()));
    }

    _nameController.addListener(_onNameChanged);
    _initialSnapshot = _currentSnapshot();
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _groupsScrollController.dispose();
    super.dispose();
  }

  void _onNameChanged() => setState(() {});

  String _currentSnapshot() {
    return jsonEncode({
      'name': _nameController.text.trim(),
      'groups': groups.map((group) => group.toJson()).toList(),
    });
  }

  bool get _hasUnsavedChanges => _currentSnapshot() != _initialSnapshot;

  void _scrollGroupsListToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_groupsScrollController.hasClients) return;
      _groupsScrollController.animateTo(
        _groupsScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _saveTraining() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      showSnack(context, "Merci de donner un nom à la séance");
      return;
    }

    if (groups.isEmpty) {
      showSnack(context, "Ajoute au moins un groupe d'exercices");
      return;
    }

    setState(() => _saving = true);

    final training = Training(
      id:
          widget.training?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      groups: groups,
      createdAt: widget.training?.createdAt ?? DateTime.now(),
    );

    try {
      await _storage.addOrUpdateTraining(training);
    } on StorageMutationBlockedException {
      if (!mounted) return;
      setState(() => _saving = false);
      showSnack(
        context,
        "Enregistrement impossible : certaines séances n'ont pas pu être "
        "lues. Les données existantes ont été conservées.",
      );
      return;
    }
    if (!mounted) return;

    setState(() => _saving = false);
    showSnack(context, "Séance enregistrée");
    Navigator.pop(context, true);
  }

  Future<void> _handleBackPressed() async {
    if (!_hasUnsavedChanges) {
      Navigator.pop(context);
      return;
    }

    final choice = await showUnsavedChangesDialog(context);

    switch (choice) {
      case 'save':
        await _saveTraining();
        break;
      case 'discard':
        if (mounted) Navigator.pop(context);
        break;
      case 'cancel':
      default:
        break;
    }
  }

  Future<void> _confirmDeleteTraining() async {
    FocusScope.of(context).unfocus();

    final training = widget.training;
    if (training == null) return;

    final bool deleted;
    try {
      deleted = await confirmAndDelete(
        context,
        title: "Supprimer la séance ?",
        content:
            'Cette action est irréversible. Supprimer "${training.name}" ?',
        onDelete: () => _storage.deleteTraining(training.id),
      );
    } on StorageMutationBlockedException {
      if (!mounted) return;
      showSnack(
        context,
        "Suppression impossible : certaines séances n'ont pas pu être lues.",
      );
      return;
    }

    if (!deleted || !mounted) return;
    Navigator.pop(context, true);
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

    setState(() => groups.add(group));
    _scrollGroupsListToEnd();
  }

  Future<void> _editGroup(int index) async {
    FocusScope.of(context).unfocus();

    final currentGroup = groups[index];
    final editedGroup = await Navigator.push<ExerciseGroup>(
      context,
      MaterialPageRoute(builder: (_) => GroupEditor(group: currentGroup)),
    );

    if (editedGroup == null || !mounted) return;

    setState(() => groups[index] = editedGroup);
  }

  Future<void> _deleteGroup(int index) async {
    final group = groups[index];
    final confirmed = await showConfirmDialog(
      context,
      title: "Supprimer le groupe ?",
      content: 'Supprimer "${group.name}" de la séance ?',
      confirmLabel: "Supprimer",
    );

    if (!confirmed || !mounted) return;
    setState(() {
      groups.removeAt(index);
      _expandedGroupIds.remove(group.id);
    });
  }

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
          centerTitle: true,
          title: Text(
            _nameController.text.trim().isEmpty
                ? "Nouvelle séance"
                : _nameController.text.trim(),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (widget.training != null)
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: "Supprimer la séance",
                onPressed: _confirmDeleteTraining,
              )
            else
              const SizedBox(width: 48),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Nom de la séance",
                  hintText: "Ex : Full Body",
                ),
              ),
              const SizedBox(height: 26),
              Expanded(
                child: ReorderableListView.builder(
                  scrollController: _groupsScrollController,
                  buildDefaultDragHandles: false,
                  itemCount: groups.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setState(() {
                      final group = groups.removeAt(oldIndex);
                      groups.insert(newIndex, group);
                    });
                  },
                  itemBuilder: (context, index) {
                    final group = groups[index];

                    return ExerciseGroupCard(
                      key: ValueKey(group.id),
                      group: group,
                      index: index,
                      expanded: _expandedGroupIds.contains(group.id),
                      onExpanded: (expanded) {
                        setState(() {
                          if (expanded) {
                            _expandedGroupIds.add(group.id);
                          } else {
                            _expandedGroupIds.remove(group.id);
                          }
                        });
                      },
                      onDelete: () => _deleteGroup(index),
                      onEdit: () => _editGroup(index),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addGroup,
                  icon: const Icon(Icons.add),
                  label: const Text("Ajouter un groupe"),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _saveTraining,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Enregistrer"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
