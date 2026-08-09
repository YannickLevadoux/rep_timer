import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/weekly_history_aggregation.dart';
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
            child: _DurationBar(
              index: index,
              day: summary.days[index],
              maximumDurationInMicroseconds: maximum,
              isToday: _sameDay(summary.days[index].date, today),
              isFuture: summary.days[index].date.isAfter(today),
              onTap: () => onSelectDay(index),
            ),
          ),
      ],
    );
  }
}

class _DurationBar extends StatelessWidget {
  const _DurationBar({
    required this.index,
    required this.day,
    required this.maximumDurationInMicroseconds,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  final int index;
  final WeeklyHistoryDay day;
  final int maximumDurationInMicroseconds;
  final bool isToday;
  final bool isFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantics = [
      formatWeeklyHistoryDayDetail(day),
      if (isToday) 'Aujourd’hui',
      if (isFuture) 'Jour à venir',
    ].join('. ');

    return Semantics(
      key: Key('weekly-duration-day-semantics-$index'),
      label: semantics,
      button: true,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          key: Key('weekly-duration-bar-$index'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => _BarValue(
                      index: index,
                      height: _barHeight(constraints.maxHeight),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    weeklyHistoryShortWeekdays[index],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: isToday ? FontWeight.bold : null,
                    ),
                  ),
                ),
                SizedBox(
                  height: 14,
                  child: isToday
                      ? const Icon(Icons.today, size: 12)
                      : isFuture
                      ? const Icon(Icons.schedule, size: 12)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _barHeight(double availableHeight) {
    if (maximumDurationInMicroseconds == 0) return 0;
    return availableHeight *
        day.duration.inMicroseconds /
        maximumDurationInMicroseconds;
  }
}

class _BarValue extends StatelessWidget {
  const _BarValue({required this.index, required this.height});

  final int index;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        key: Key('weekly-duration-value-$index'),
        width: 22,
        height: height == 0 ? 2 : height,
        decoration: BoxDecoration(
          color: height == 0
              ? Theme.of(context).colorScheme.outlineVariant
              : Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    );
  }
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
