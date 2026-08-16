import 'package:flutter/material.dart';

import '../models/training_item.dart';
import '../utils/exercise_icons.dart';
import 'number_wheel_field.dart';
import 'timed_inline_picker_row.dart';

class TimedExerciseMinutesRow extends StatelessWidget {
  const TimedExerciseMinutesRow({
    super.key,
    required this.item,
    required this.minutes,
    required this.minimum,
    required this.maximum,
    required this.onEdit,
    required this.onChanged,
  });

  final TrainingItem item;
  final int minutes;
  final int minimum;
  final int maximum;
  final VoidCallback onEdit;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => TimedInlinePickerRow(
    title: item.name,
    leading: Icon(iconForExercise(item.iconName)),
    action: IconButton(
      onPressed: onEdit,
      tooltip: "Modifier l'effort",
      icon: const Icon(Icons.edit),
    ),
    picker: NumberWheelField(
      min: minimum,
      max: maximum,
      value: minutes,
      label: 'min',
      onChanged: onChanged,
    ),
    basePickerWidth: 64,
  );
}
