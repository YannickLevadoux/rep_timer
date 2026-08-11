import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/weekly_history_aggregation.dart';
import 'weekly_history_day_bar.dart';
import 'weekly_history_day_labels.dart';

class WeeklyHistoryDurationChart extends StatelessWidget {
  const WeeklyHistoryDurationChart({
    super.key,
    required this.summary,
    required this.today,
    required this.onSelectDay,
  });

  final WeeklyHistorySummary summary;
  final DateTime today;
  final ValueChanged<int> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final maximum = summary.days.fold<int>(
      0,
      (value, day) => math.max(value, day.duration.inMicroseconds),
    );

    return Row(
      key: const Key('weekly-duration-chart'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < summary.days.length; index++)
          Expanded(
            child: WeeklyHistoryDayBar(
              keyPrefix: 'weekly-duration',
              index: index,
              day: summary.days[index],
              today: today,
              detail: formatWeeklyHistoryDurationDaySemantic(
                summary.days[index],
              ),
              value: WeeklyHistoryBarValue(
                valueKey: Key('weekly-duration-value-$index'),
                fraction: _fraction(summary.days[index], maximum),
                child: ColoredBox(color: Theme.of(context).colorScheme.primary),
              ),
              onTap: () => onSelectDay(index),
            ),
          ),
      ],
    );
  }
}

double _fraction(WeeklyHistoryDay day, int maximum) =>
    maximum == 0 ? 0 : day.duration.inMicroseconds / maximum;
