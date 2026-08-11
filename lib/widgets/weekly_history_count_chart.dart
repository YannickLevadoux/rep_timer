import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/weekly_history_aggregation.dart';
import '../utils/history_status_colors.dart';
import 'weekly_history_day_bar.dart';
import 'weekly_history_day_labels.dart';

class WeeklyHistoryCountChart extends StatelessWidget {
  const WeeklyHistoryCountChart({
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
      (value, day) => math.max(value, day.sessionCount),
    );

    return Row(
      key: const Key('weekly-count-chart'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < summary.days.length; index++)
          Expanded(
            child: WeeklyHistoryDayBar(
              keyPrefix: 'weekly-count',
              index: index,
              day: summary.days[index],
              today: today,
              detail: formatWeeklyHistoryCountDayDetail(summary.days[index]),
              value: WeeklyHistoryBarValue(
                valueKey: Key('weekly-count-value-$index'),
                fraction: _fraction(summary.days[index], maximum),
                child: _CountValue(index: index, day: summary.days[index]),
              ),
              onTap: () => onSelectDay(index),
            ),
          ),
      ],
    );
  }
}

class _CountValue extends StatelessWidget {
  const _CountValue({required this.index, required this.day});

  final int index;
  final WeeklyHistoryDay day;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (day.incompleteCount > 0)
          Expanded(
            flex: day.incompleteCount,
            child: ColoredBox(
              key: Key('weekly-count-incomplete-value-$index'),
              color: incompleteHistoryColor(context),
            ),
          ),
        if (day.completedCount > 0)
          Expanded(
            flex: day.completedCount,
            child: ColoredBox(
              key: Key('weekly-count-completed-value-$index'),
              color: completedHistoryColor(context),
            ),
          ),
      ],
    );
  }
}

double _fraction(WeeklyHistoryDay day, int maximum) =>
    maximum == 0 ? 0 : day.sessionCount / maximum;
