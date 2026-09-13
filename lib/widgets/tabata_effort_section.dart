import 'package:flutter/material.dart';

import 'duration_minutes_seconds_picker.dart';
import 'timed_inline_picker_row.dart';

class TabataEffortSection extends StatelessWidget {
  const TabataEffortSection({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onEditExercises,
  });

  final Duration value;
  final ValueChanged<Duration> onChanged;
  final VoidCallback onEditExercises;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TimedInlinePickerRow(
        key: const Key('tabata-effort-row'),
        title: 'Durée des efforts',
        leading: const Icon(Icons.fitness_center),
        picker: DurationMinutesSecondsPicker(
          value: value,
          onChanged: onChanged,
        ),
        basePickerWidth: 176,
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const Key('edit-tabata-exercises'),
          onPressed: onEditExercises,
          icon: const Icon(Icons.edit),
          label: const Text('Modifier les exercices'),
        ),
      ),
    ],
  );
}
