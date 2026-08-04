import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/training.dart';

class TrainingEditorController extends ChangeNotifier {
  TrainingEditorController(this._source) {
    nameController = TextEditingController(text: _source?.name ?? '');
    groups.addAll(_source?.groups.map((group) => group.copyWith()) ?? const []);
    nameController.addListener(_onNameChanged);
    _initialSnapshot = _currentSnapshot();
  }

  final Training? _source;
  final List<ExerciseGroup> groups = [];
  final Set<String> _expandedGroupIds = {};
  final ScrollController groupsScrollController = ScrollController();

  late final TextEditingController nameController;
  late final String _initialSnapshot;
  bool saving = false;

  String get name => nameController.text.trim();
  bool get hasUnsavedChanges => _currentSnapshot() != _initialSnapshot;

  String _currentSnapshot() => jsonEncode({
    'name': name,
    'groups': groups.map((group) => group.toJson()).toList(),
  });

  void _onNameChanged() => notifyListeners();

  bool isExpanded(String groupId) => _expandedGroupIds.contains(groupId);

  void setExpanded(String groupId, bool expanded) {
    if (expanded) {
      _expandedGroupIds.add(groupId);
    } else {
      _expandedGroupIds.remove(groupId);
    }
    notifyListeners();
  }

  void addGroup(ExerciseGroup group) {
    groups.add(group);
    notifyListeners();
  }

  void replaceGroup(int index, ExerciseGroup group) {
    groups[index] = group;
    notifyListeners();
  }

  void removeGroup(int index) {
    final group = groups.removeAt(index);
    _expandedGroupIds.remove(group.id);
    notifyListeners();
  }

  void reorderGroups(int oldIndex, int newIndex) {
    final group = groups.removeAt(oldIndex);
    groups.insert(newIndex, group);
    notifyListeners();
  }

  void setSaving(bool value) {
    saving = value;
    notifyListeners();
  }

  Training buildTraining() => Training(
    id: _source?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
    name: name,
    groups: groups,
    createdAt: _source?.createdAt ?? DateTime.now(),
  );

  void scrollGroupsListToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!groupsScrollController.hasClients) return;
      groupsScrollController.animateTo(
        groupsScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    nameController.removeListener(_onNameChanged);
    nameController.dispose();
    groupsScrollController.dispose();
    super.dispose();
  }
}
