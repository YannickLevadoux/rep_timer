import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/group_type.dart';
import '../models/training_item.dart';

class GroupEditorController extends ChangeNotifier {
  GroupEditorController(ExerciseGroup source) {
    group = source.copyWith();
    nameController = TextEditingController(text: group.name);
    _initialSnapshot = _currentSnapshot();
  }

  late final ExerciseGroup group;
  late final TextEditingController nameController;
  late final String _initialSnapshot;

  String get name => nameController.text.trim();

  bool get hasUnsavedChanges => _currentSnapshot() != _initialSnapshot;

  String _currentSnapshot() => jsonEncode({...group.toJson(), 'name': name});

  void setType(GroupType type) {
    group.type = type;
    notifyListeners();
  }

  void setRounds(int rounds) {
    group.rounds = rounds;
    notifyListeners();
  }

  void addItem(TrainingItem item) {
    group.items.add(item);
    notifyListeners();
  }

  void updateRest(int index, Duration duration) {
    group.items[index].duration = duration;
    notifyListeners();
  }

  void updateExercise(int index, TrainingItem result) {
    final item = group.items[index];
    item.name = result.name;
    item.repetitions = result.repetitions;
    item.duration = result.duration;
    item.isFreeDuration = result.isFreeDuration;
    item.comment = result.comment;
    item.iconName = result.iconName;
    notifyListeners();
  }

  void removeItem(int index) {
    group.items.removeAt(index);
    notifyListeners();
  }

  void reorderItems(int oldIndex, int newIndex) {
    final item = group.items.removeAt(oldIndex);
    group.items.insert(newIndex, item);
    notifyListeners();
  }

  ExerciseGroup save() {
    group.name = name;
    return group;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}
