import 'package:flutter/foundation.dart';

import '../models/exercise_group.dart';
import '../models/tabata_config.dart';
import '../models/training_item.dart';
import '../utils/exercise_icons.dart';
import '../validation/business_validation.dart';

mixin GroupEditorTabataActions on ChangeNotifier {
  ExerciseGroup get group;

  TabataConfig get _tabata =>
      group.tabataConfig ?? (throw StateError('Configuration Tabata absente'));

  int get tabataRounds => _tabata.rounds;
  int get tabataCycleCount => _tabata.exercises.length;
  bool get canDeleteTabataFinalRest =>
      tabataRounds == 1 && _tabata.finalRestDuration != null;

  bool get lastTabataExerciseIsCustomized {
    final exercise = _tabata.exercises.last;
    final generatedName = 'Effort $tabataCycleCount';
    final name = exercise.name.trim();
    return (name.isNotEmpty && name != 'Effort' && name != generatedName) ||
        (exercise.iconName != null &&
            exercise.iconName != defaultExerciseIconName) ||
        (exercise.comment?.trim().isNotEmpty ?? false);
  }

  void setRounds(int rounds) {
    group.rounds = rounds;
    notifyListeners();
  }

  void setTabataRounds(int rounds) {
    if (rounds < BusinessLimits.minimumCount ||
        rounds > BusinessLimits.maximumTabataRounds) {
      return;
    }
    _tabata.rounds = rounds;
    notifyListeners();
  }

  void configureNewTabataExerciseName({required bool prefill}) {
    final exercise = _tabata.exercises.single;
    exercise
      ..name = prefill ? 'Effort 1' : ''
      ..iconName ??= defaultExerciseIconName;
    group.items[0] = exercise;
    notifyListeners();
  }

  bool addTabataExercise() {
    if (tabataCycleCount >= BusinessLimits.maximumCount) return false;
    final exercise = TrainingItem(
      type: ItemType.exercise,
      name: 'Effort ${tabataCycleCount + 1}',
      duration: _tabata.effortDuration,
      iconName: defaultExerciseIconName,
    );
    _applyTabataExercises([..._tabata.exercises, exercise]);
    return true;
  }

  bool removeLastTabataExercise() {
    if (tabataCycleCount <= BusinessLimits.minimumCount) return false;
    _applyTabataExercises(_tabata.exercises.sublist(0, tabataCycleCount - 1));
    return true;
  }

  bool replaceTabataExercises(List<TrainingItem> exercises) {
    if (exercises.isEmpty || exercises.length > BusinessLimits.maximumCount) {
      return false;
    }
    final duration = _tabata.effortDuration;
    final valid = exercises.every(
      (exercise) =>
          exercise.type == ItemType.exercise &&
          exercise.duration == duration &&
          BusinessValidation.validateItem(exercise).isEmpty,
    );
    if (!valid) return false;
    _applyTabataExercises(exercises.map((item) => item.copyWith()).toList());
    return true;
  }

  void _applyTabataExercises(List<TrainingItem> exercises) {
    _tabata.exercises = exercises;
    group.rounds = exercises.length;
    group.items
      ..clear()
      ..add(_tabata.exercises.first)
      ..add(_tabata.legacyRestItem);
    notifyListeners();
  }

  void setEffortDuration(Duration value) {
    final tabata = group.tabataConfig;
    if (tabata == null) {
      group.items.first.duration = value;
    } else {
      tabata.setEffortDuration(value);
    }
    notifyListeners();
  }

  void setRequiredRestDuration(Duration value) {
    group.items[1].duration = value;
    _tabata.restDuration = value;
    notifyListeners();
  }

  void setFinalRestEnabled(bool enabled) {
    if (!enabled && tabataRounds > 1) return;
    group.finalRestDuration = enabled ? _tabata.restDuration : null;
    notifyListeners();
  }

  void setFinalRestDuration(Duration value) {
    group.finalRestDuration = value;
    notifyListeners();
  }
}
