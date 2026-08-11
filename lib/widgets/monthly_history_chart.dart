import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/monthly_history_aggregation.dart';
import '../services/weekly_history_aggregation.dart';
import 'monthly_history_week_bar.dart';

class MonthlyHistoryChart extends StatelessWidget {
  const MonthlyHistoryChart({
    super.key,
    required this.summary,
    required this.today,
    required this.showDuration,
    required this.durationLabelHeight,
    required this.onOpenWeek,
  });

  final MonthlyHistorySummary summary;
  final DateTime today;
  final bool showDuration;
  final double durationLabelHeight;
  final ValueChanged<LocalWeek> onOpenWeek;

  @override
  Widget build(BuildContext context) {
    final maximum = summary.weeks.fold<int>(0, (value, bucket) {
      final bucketValue = showDuration
          ? bucket.totalDuration.inMicroseconds
          : bucket.totalCount;
      return math.max(value, bucketValue);
    });

    return Row(
      key: const Key('monthly-history-chart'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < summary.weeks.length; index++)
          Expanded(
            child: MonthlyHistoryWeekBar(
              index: index,
              bucket: summary.weeks[index],
              today: today,
              showDuration: showDuration,
              durationLabelHeight: durationLabelHeight,
              maximum: maximum,
              onTap: () => onOpenWeek(summary.weeks[index].week),
            ),
          ),
      ],
    );
  }
}
