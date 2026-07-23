import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/training.dart';
import '../services/training_storage.dart';
import '../utils/snack.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/exercise_group_card.dart';
import 'exercise_group_editor.dart';

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

  bool _saving = false;
  late final String _initialSnapshot;

  @override
  void initState() {
    super.initState();

    final existing = widget.training;
    if (existing != null) {
      _nameController.text = existing.name;
      groups.addAll(
        existing.groups.map((group) => ExerciseGroup.fromJson(group.toJson())),
      );
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

    await _storage.addOrUpdateTraining(
      Training(
        id:
            widget.training?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        groups: groups,
        createdAt: widget.training?.createdAt ?? DateTime.now(),
      ),
    );

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
      case null:
      default:
        break;
    }
  }

  Future<void> _confirmDeleteTraining() async {
    FocusScope.of(context).unfocus();
    final training = widget.training;
    if (training == null) return;

    final deleted = await confirmAndDelete(
      context,
      title: "Supprimer la séance ?",
      content: 'Cette action est irréversible. Supprimer "${training.name}" ?',
      onDelete: () => _storage.deleteTraining(training.id),
    );

    if (!deleted || !mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _openGroupEditor({ExerciseGroup? group}) async {
    FocusScope.of(context).unfocus();

    final result = await Navigator.push<ExerciseGroup>(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseGroupEditorScreen(group: group),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      if (group == null) {
        groups.add(result);
      } else {
        groups[groups.indexOf(group)] = result;
      }
    });

    if (group == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_groupsScrollController.hasClients) return;
        _groupsScrollController.animateTo(
          _groupsScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Future<void> _confirmDeleteGroup(ExerciseGroup group) async {
    final confirmed = await showConfirmDialog(
      context,
      title: "Supprimer le groupe ?",
      content:
          'Le groupe "${group.name}" et tous ses éléments seront supprimés.',
      confirmLabel: "Supprimer",
    );

    if (!confirmed || !mounted) return;
    setState(() => groups.remove(group));
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
              const SizedBox(height: 16),
              Expanded(
                child: groups.isEmpty
                    ? const Center(child: Text("Aucun groupe"))
                    : ReorderableListView.builder(
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
                            onEdit: () => _openGroupEditor(group: group),
                            onDelete: () => _confirmDeleteGroup(group),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openGroupEditor,
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
