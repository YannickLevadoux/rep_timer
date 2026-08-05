import 'package:flutter/material.dart';

import '../models/training_item.dart';
import '../utils/exercise_icons.dart';
import '../utils/validation_messages.dart';
import '../validation/business_validation.dart';
import 'duration_minutes_seconds_picker.dart';

enum ExerciseInputMode { repetitions, duration, freeDuration }

/// État et validation du formulaire d'exercice, indépendants du dialogue.
class ExerciseFormController extends ChangeNotifier {
  ExerciseFormController({TrainingItem? initial, String defaultName = ''})
    : isEditing = initial != null,
      nameController = TextEditingController(
        text: initial?.name ?? defaultName,
      ),
      repetitionsController = TextEditingController(
        text: initial?.repetitions?.toString() ?? '',
      ),
      commentController = TextEditingController(text: initial?.comment ?? ''),
      mode = _modeOf(initial),
      duration = initial?.duration ?? defaultExerciseDuration,
      iconName = initial?.iconName ?? defaultExerciseIconName;

  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController repetitionsController;
  final TextEditingController commentController;

  ExerciseInputMode mode;
  Duration duration;
  String iconName;
  String? nameError;
  String? repetitionsError;
  String? commentError;

  static ExerciseInputMode _modeOf(TrainingItem? item) {
    if (item?.isFreeDuration ?? false) {
      return ExerciseInputMode.freeDuration;
    }
    if (item?.duration != null) return ExerciseInputMode.duration;
    return ExerciseInputMode.repetitions;
  }

  void setMode(ExerciseInputMode value) {
    mode = value;
    repetitionsError = null;
    notifyListeners();
  }

  void setDuration(Duration value) {
    duration = value;
    notifyListeners();
  }

  void setIconName(String value) {
    iconName = value;
    notifyListeners();
  }

  TrainingItem? validateAndBuild() {
    final nameIssue = BusinessValidation.validateName(
      nameController.text,
      field: BusinessField.exerciseName,
    );
    final repetitionsIssue = mode == ExerciseInputMode.repetitions
        ? BusinessValidation.validateCountText(
            repetitionsController.text,
            field: BusinessField.repetitions,
          )
        : null;
    final durationIssue = mode == ExerciseInputMode.duration
        ? BusinessValidation.validateDuration(duration)
        : null;
    final currentCommentIssue = BusinessValidation.validateComment(
      commentController.text,
    );

    nameError = nameIssue == null ? null : validationMessage(nameIssue);
    repetitionsError = repetitionsIssue == null
        ? null
        : validationMessage(repetitionsIssue);
    commentError = currentCommentIssue == null
        ? null
        : validationMessage(currentCommentIssue);
    notifyListeners();

    if (nameIssue != null ||
        repetitionsIssue != null ||
        durationIssue != null ||
        currentCommentIssue != null) {
      return null;
    }

    return TrainingItem(
      type: ItemType.exercise,
      name: BusinessValidation.normalizeName(nameController.text),
      repetitions: mode == ExerciseInputMode.repetitions
          ? int.parse(repetitionsController.text.trim())
          : null,
      duration: mode == ExerciseInputMode.duration ? duration : null,
      isFreeDuration: mode == ExerciseInputMode.freeDuration,
      comment: BusinessValidation.normalizeComment(commentController.text),
      iconName: iconName,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    repetitionsController.dispose();
    commentController.dispose();
    super.dispose();
  }
}
