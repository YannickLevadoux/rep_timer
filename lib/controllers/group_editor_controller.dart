import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/group_type.dart';
import '../models/training_item.dart';
import '../validation/business_validation.dart';

class GroupEditorController extends ChangeNotifier {
  GroupEditorController(ExerciseGroup source) {
    group = source.copyWith();
    _drafts[group.type] = group;
    nameController = TextEditingController(text: group.name);
    nameController.addListener(_onNameChanged);
    _initialSnapshot = _currentSnapshot();
  }

  late ExerciseGroup group;
  late final TextEditingController nameController;
  late final String _initialSnapshot;
  final Map<GroupType, ExerciseGroup> _drafts = {};
  String get name => nameController.text.trim();
  bool get hasUnsavedChanges => _currentSnapshot() != _initialSnapshot;
  String _currentSnapshot() => jsonEncode({
    'selectedType': group.type.name,
    'drafts': _drafts.map(
      (type, draft) => MapEntry(
        type.name,
        draft == group ? {...draft.toJson(), 'name': name} : draft.toJson(),
      ),
    ),
  });
  void _onNameChanged() => notifyListeners();
  bool requiresReplacementConfirmation(GroupType target) =>
      target != group.type && (target.isTimed || group.type.isTimed);
  void setType(GroupType type) => switchType(type);

  void switchType(GroupType type) {
    if (type == group.type) return;
    group.name = name;
    final current = group;
    if (!type.isTimed && !current.type.isTimed) {
      group = _createDraft(type, current);
      _drafts[type] = group;
    } else {
      group = _drafts.putIfAbsent(type, () => _createDraft(type, current));
    }
    nameController.text = group.name;
    notifyListeners();
  }

  ExerciseGroup _createDraft(GroupType type, ExerciseGroup current) {
    if (!type.isTimed && !current.type.isTimed) {
      final draft = current.copyWith(type: type);
      _initializeSequence(draft);
      return draft;
    }
    return switch (type) {
      GroupType.tabata => ExerciseGroup.tabata(id: current.id),
      GroupType.amrap => ExerciseGroup.amrap(id: current.id),
      GroupType.emom => ExerciseGroup.emom(id: current.id),
      GroupType.free => ExerciseGroup(
        id: current.id,
        name: 'Groupe libre',
        items: [],
      ),
      GroupType.variableRepetitions => ExerciseGroup(
        id: current.id,
        name: 'Répétitions variables',
        type: type,
        repetitionSequence: const [1],
        items: [],
      ),
    };
  }

  void _initializeSequence(ExerciseGroup draft) {
    if (draft.type == GroupType.variableRepetitions &&
        draft.repetitionSequence.isEmpty) {
      final firstRepetitions = group.items
          .where(
            (item) =>
                item.repetitions != null &&
                BusinessValidation.validateCount(
                      item.repetitions,
                      field: BusinessField.repetitions,
                    ) ==
                    null,
          )
          .map((item) => item.repetitions!)
          .firstOrNull;
      final validRounds =
          BusinessValidation.validateCount(
                group.rounds,
                field: BusinessField.groupRounds,
              ) ==
              null
          ? group.rounds
          : BusinessLimits.minimumCount;
      draft.repetitionSequence = List<int>.filled(
        validRounds,
        firstRepetitions ?? BusinessLimits.minimumCount,
      );
    }
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

  @override
  void dispose() {
    nameController.removeListener(_onNameChanged);
    nameController.dispose();
    super.dispose();
  }
}
