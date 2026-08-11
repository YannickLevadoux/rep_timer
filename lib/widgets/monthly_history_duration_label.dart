import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'monthly_history_bar_label.dart';

class MonthlyHistoryDurationLabel extends StatelessWidget {
  const MonthlyHistoryDurationLabel({
    super.key,
    required this.index,
    required this.duration,
  });

  final int index;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: Key('monthly-duration-badge-$index'),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        child: Center(
          child: Text(
            formatMonthlyHistoryDurationLabel(duration),
            key: Key('monthly-duration-label-$index'),
            textAlign: TextAlign.center,
            style: monthlyHistoryBarLabelStyle(context),
          ),
        ),
      ),
    );
  }
}

double monthlyHistoryDurationLabelHeight(
  BuildContext context,
  Duration duration, {
  required double maxWidth,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: formatMonthlyHistoryDurationLabel(duration),
      style: monthlyHistoryBarLabelStyle(context),
    ),
    textAlign: TextAlign.center,
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: math.max(1, maxWidth - 8));
  return painter.height + 6;
}

String formatMonthlyHistoryDurationLabel(Duration duration) {
  final clamped = duration.isNegative ? Duration.zero : duration;
  final parts = <String>[];
  if (clamped.inHours > 0) parts.add('${clamped.inHours} h');
  final minutes = clamped.inMinutes.remainder(60);
  if (minutes > 0) parts.add('$minutes min');
  final seconds = clamped.inSeconds.remainder(60);
  if (seconds > 0) parts.add('$seconds s');
  return parts.isEmpty ? '< 1 s' : parts.join('\n');
}
