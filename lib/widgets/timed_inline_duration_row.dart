import 'package:flutter/material.dart';

import '../models/training_item.dart';
import '../utils/exercise_icons.dart';
import 'duration_minutes_seconds_picker.dart';

class TimedExerciseDurationRow extends StatelessWidget {
  const TimedExerciseDurationRow({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onChanged,
  });

  final TrainingItem item;
  final VoidCallback onEdit;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) => _InlineTimedDurationRow(
    title: item.name,
    leading: Icon(iconForExercise(item.iconName)),
    action: IconButton(
      onPressed: onEdit,
      tooltip: "Modifier l'effort",
      icon: const Icon(Icons.edit),
    ),
    value: item.duration ?? Duration.zero,
    onChanged: onChanged,
  );
}

class TimedRestDurationRow extends StatelessWidget {
  const TimedRestDurationRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.onDelete,
  });

  final String title;
  final Duration value;
  final ValueChanged<Duration> onChanged;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => _InlineTimedDurationRow(
    title: title,
    action: onDelete == null
        ? null
        : IconButton(
            onPressed: onDelete,
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline),
          ),
    value: value,
    onChanged: onChanged,
  );
}

class _InlineTimedDurationRow extends StatelessWidget {
  const _InlineTimedDurationRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.leading,
    this.action,
  });

  static const double _basePickerWidth = 176;
  static const double _minimumLeadingWidth = 80;

  final String title;
  final Duration value;
  final ValueChanged<Duration> onChanged;
  final Widget? leading;
  final Widget? action;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final naturalPickerWidth =
          _basePickerWidth + (textScale - 1).clamp(0, 2) * 24;
      final pickerWidth = (constraints.maxWidth - _minimumLeadingWidth).clamp(
        0.0,
        naturalPickerWidth,
      );
      return Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 8)],
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ?action,
              ],
            ),
          ),
          SizedBox(
            width: pickerWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: naturalPickerWidth,
                child: DurationMinutesSecondsPicker(
                  value: value,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
