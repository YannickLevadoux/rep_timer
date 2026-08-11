import 'package:flutter/material.dart';

import '../services/monthly_history_aggregation.dart';
import '../utils/history_status_colors.dart';

class MonthlyHistoryStatusSegments extends StatelessWidget {
  const MonthlyHistoryStatusSegments({
    super.key,
    required this.index,
    required this.bucket,
  });

  final int index;
  final MonthlyHistoryWeekBucket bucket;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (bucket.incompleteCount > 0)
            Expanded(
              flex: bucket.incompleteCount,
              child: ColoredBox(
                key: Key('monthly-incomplete-value-$index'),
                color: incompleteHistoryColor(context),
              ),
            ),
          if (bucket.completedCount > 0)
            Expanded(
              flex: bucket.completedCount,
              child: ColoredBox(
                key: Key('monthly-completed-value-$index'),
                color: completedHistoryColor(context),
              ),
            ),
        ],
      ),
    );
  }
}
