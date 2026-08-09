import 'package:flutter/material.dart';

import '../services/monthly_history_aggregation.dart';
import '../utils/history_status_colors.dart';
import 'monthly_history_labels.dart';

class MonthlyHistoryWeekBar extends StatelessWidget {
  const MonthlyHistoryWeekBar({
    super.key,
    required this.index,
    required this.bucket,
    required this.today,
    required this.showDuration,
    required this.maximum,
    required this.onTap,
  });

  final int index;
  final MonthlyHistoryWeekBucket bucket;
  final DateTime today;
  final bool showDuration;
  final int maximum;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final future = bucket.isEntirelyFuture(today);
    final semantics = formatMonthlyWeekDetail(
      bucket,
      showDuration: showDuration,
      isFuture: future,
    );
    final value = showDuration
        ? bucket.totalDuration.inMicroseconds
        : bucket.totalCount;
    final fraction = maximum == 0 ? 0.0 : value / maximum;

    return Semantics(
      key: Key('monthly-week-semantics-$index'),
      label: semantics,
      button: true,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Tooltip(
          message: semantics,
          child: InkWell(
            key: Key('monthly-week-bar-$index'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  Expanded(
                    child: Opacity(
                      opacity: future ? 0.45 : 1,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          key: Key('monthly-week-value-$index'),
                          heightFactor: fraction == 0 ? null : fraction,
                          widthFactor: 0.72,
                          child: _barValue(context, fraction),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatMonthlyBucketLabel(bucket),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  SizedBox(
                    height: 14,
                    child: future ? const Icon(Icons.schedule, size: 12) : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _barValue(BuildContext context, double fraction) {
    if (fraction == 0) {
      return Container(
        height: 2,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      );
    }
    return showDuration
        ? _DurationValue(index: index)
        : _CountValue(index: index, bucket: bucket);
  }
}

class _DurationValue extends StatelessWidget {
  const _DurationValue({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: Key('monthly-duration-value-$index'),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }
}

class _CountValue extends StatelessWidget {
  const _CountValue({required this.index, required this.bucket});

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
