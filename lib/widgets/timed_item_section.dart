import 'package:flutter/material.dart';

import '../models/training_item.dart';
import '../utils/exercise_icons.dart';
import '../utils/formatters.dart';
import 'duration_minutes_seconds_picker.dart';

class TimedExerciseSection extends StatelessWidget {
  const TimedExerciseSection({
    super.key,
    required this.item,
    required this.onEdit,
  });

  final TrainingItem item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(iconForExercise(item.iconName)),
      title: Text(item.name),
      subtitle: Text(formatDuration(item.duration ?? Duration.zero)),
      trailing: IconButton(
        onPressed: onEdit,
        tooltip: "Modifier l'effort",
        icon: const Icon(Icons.edit),
      ),
    );
  }
}

class TimedDurationSection extends StatelessWidget {
  const TimedDurationSection({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.minimum,
    this.maximum,
    this.onDelete,
  });

  final String title;
  final Duration value;
  final ValueChanged<Duration> onChanged;
  final Duration? minimum;
  final Duration? maximum;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                tooltip: 'Supprimer',
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: DurationMinutesSecondsPicker(
            value: value,
            minimum: minimum ?? const Duration(seconds: 1),
            maximum: maximum ?? const Duration(hours: 2, seconds: 59),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
