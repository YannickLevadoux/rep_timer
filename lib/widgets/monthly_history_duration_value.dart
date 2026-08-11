import 'package:flutter/material.dart';

import 'monthly_history_bar_label.dart';

class MonthlyHistoryDurationValue extends StatelessWidget {
  const MonthlyHistoryDurationValue({
    super.key,
    required this.index,
    required this.duration,
  });

  final int index;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final text = _formatDuration(duration);
    final labelHeight = monthlyHistoryBarLabelHeight(context, text);
    return LayoutBuilder(
      builder: (context, constraints) {
        final inside =
            constraints.maxHeight >= labelHeight + 2 &&
            constraints.maxWidth >= monthlyHistoryBarLabelWidth(context, text);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                key: Key('monthly-duration-value-$index'),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
            ),
            Positioned(
              key: Key(
                'monthly-duration-label-${inside ? 'inside' : 'outside'}-$index',
              ),
              top: inside
                  ? (constraints.maxHeight - labelHeight) / 2
                  : -labelHeight - 2,
              left: 0,
              right: 0,
              height: labelHeight,
              child: MonthlyHistoryBarLabel(
                textKey: Key('monthly-duration-label-$index'),
                text: text,
              ),
            ),
          ],
        );
      },
    );
  }
}

String _formatDuration(Duration duration) {
  final clamped = duration.isNegative ? Duration.zero : duration;
  final parts = <String>[];
  if (clamped.inHours > 0) parts.add('${clamped.inHours} h');
  final minutes = clamped.inMinutes.remainder(60);
  if (minutes > 0) parts.add('$minutes min');
  final seconds = clamped.inSeconds.remainder(60);
  if (seconds > 0) parts.add('$seconds s');
  return parts.isEmpty ? '< 1 s' : parts.join('\n');
}
