import 'package:flutter/material.dart';

import '../../models/training_item.dart';
import '../../utils/validation_messages.dart';
import '../../validation/business_validation.dart';

class TabataExerciseEntry {
  TabataExerciseEntry(TrainingItem item)
    : key = UniqueKey(),
      nameController = TextEditingController(text: item.name),
      iconName = item.iconName,
      comment = item.comment;

  final Key key;
  final TextEditingController nameController;
  String? iconName;
  String? comment;
  String? nameError;
  String? commentError;

  bool validate() {
    final nameIssue = BusinessValidation.validateName(
      nameController.text,
      field: BusinessField.exerciseName,
    );
    final commentIssue = BusinessValidation.validateComment(comment);
    nameError = nameIssue == null ? null : validationMessage(nameIssue);
    commentError = commentIssue == null
        ? null
        : validationMessage(commentIssue);
    return nameIssue == null && commentIssue == null;
  }

  TrainingItem toItem(Duration duration) => TrainingItem(
    type: ItemType.exercise,
    name: BusinessValidation.normalizeName(nameController.text),
    duration: duration,
    comment: BusinessValidation.normalizeComment(comment),
    iconName: iconName,
  );

  void dispose() => nameController.dispose();
}
