import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/group_type.dart';
import '../models/training_item.dart';
import 'group_editor_draft_factory.dart';

class GroupEditorController extends ChangeNotifier {
  GroupEditorController(
    ExerciseGroup source, {
    bool requiresInitialTypeSelection = false,
  }) : _sourceId = source.id,
       _group = requiresInitialTypeSelection ? null : source.copyWith() {
    final initialGroup = _group;
    if (initialGroup != null) _drafts[initialGroup.type] = initialGroup;
    nameController = TextEditingController(text: initialGroup?.name ?? '');
    nameController.addListener(_onNameChanged);
    _initialSnapshot = _currentSnapshot();
  }

  final String _sourceId;
  ExerciseGroup? _group;
  late final TextEditingController nameController;
  late final String _initialSnapshot;
  final Map<GroupType, ExerciseGroup> _drafts = {};
  ExerciseGroup get group =>
      _group ?? (throw StateError('Type non sélectionné'));
  GroupType? get selectedType => _group?.type;
  bool get hasSelectedType => _group != null;
  String get name => nameController.text.trim();
  bool get hasUnsavedChanges => _currentSnapshot() != _initialSnapshot;
  String _currentSnapshot() => jsonEncode({
    'selectedType': selectedType?.name,
    'drafts': _drafts.map(
      (type, draft) => MapEntry(
        type.name,
        draft == _group ? {...draft.toJson(), 'name': name} : draft.toJson(),
      ),
    ),
  });
  void _onNameChanged() => notifyListeners();
  bool requiresReplacementConfirmation(GroupType target) =>
      _group != null &&
      target != group.type &&
      (target.isTimed || group.type.isTimed);
  void setType(GroupType type) => switchType(type);

  void switchType(GroupType type) {
    if (_group == null) {
      _group = GroupEditorDraftFactory.initial(type, id: _sourceId);
      _drafts[type] = group;
      nameController.text = group.name;
      notifyListeners();
      return;
    }
    if (type == group.type) return;
    group.name = name;
    final current = group;
    if (!type.isTimed && !current.type.isTimed) {
      _group = GroupEditorDraftFactory.fromCurrent(type, current);
      _drafts[type] = group;
    } else {
      _group = _drafts.putIfAbsent(
        type,
        () => GroupEditorDraftFactory.fromCurrent(type, current),
      );
    }
    nameController.text = group.name;
    notifyListeners();
  }

  void setRounds(int rounds) => _mutate(() => group.rounds = rounds);

  void setRepetitionSequence(List<int> values) {
    group.repetitionSequence = List<int>.of(values);
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

  void setEffortDuration(Duration value) =>
      _mutate(() => group.items.first.duration = value);

  void setRequiredRestDuration(Duration value) =>
      _mutate(() => group.items[1].duration = value);

  void setFinalRestEnabled(bool enabled) {
    group.finalRestDuration = enabled ? ExerciseGroup.defaultTabataRest : null;
    notifyListeners();
  }

  void setPostGroupRestEnabled(bool enabled) {
    group.postGroupRestDuration = enabled
        ? ExerciseGroup.defaultPostGroupRest
        : null;
    notifyListeners();
  }

  void setFinalRestDuration(Duration value) =>
      _mutate(() => group.finalRestDuration = value);

  void setPostGroupRestDuration(Duration value) =>
      _mutate(() => group.postGroupRestDuration = value);

  void _mutate(VoidCallback mutation) {
    mutation();
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

  void updateTimedExercise(TrainingItem result) {
    final duration = group.items.first.duration;
    group.items[0] = TrainingItem(
      type: ItemType.exercise,
      name: result.name,
      duration: duration,
      comment: result.comment,
      iconName: result.iconName,
    );
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

  ExerciseGroup? saveIfSelected() {
    if (!hasSelectedType) return null;
    return save();
  }

  @override
  void dispose() {
    nameController.removeListener(_onNameChanged);
    nameController.dispose();
    super.dispose();
  }
}
