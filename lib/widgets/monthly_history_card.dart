import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/monthly_history_aggregation.dart';
import '../services/weekly_history_aggregation.dart';
import '../utils/formatters.dart';
import '../utils/history_status_colors.dart';
import 'monthly_history_month_navigation.dart';

/// Graphique mensuel compact, partagé par les métriques séances et durée.
class MonthlyHistoryCard extends StatelessWidget {
  const MonthlyHistoryCard({
    super.key,
    required this.summary,
    required this.today,
    required this.showDuration,
    required this.canGoNext,
    required this.isCurrentMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onOpenWeek,
  });

  final MonthlyHistorySummary summary;
  final DateTime today;
  final bool showDuration;
  final bool canGoNext;
  final bool isCurrentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final ValueChanged<LocalWeek> onOpenWeek;

  @override
  Widget build(BuildContext context) {
    final minimumChartHeight = isCurrentMonth ? 128.0 : 120.0;
    final maximumChartHeight = isCurrentMonth ? 168.0 : 120.0;
    final chartHeight = (MediaQuery.sizeOf(context).height * 0.24).clamp(
      minimumChartHeight,
      maximumChartHeight,
    );
    final semanticSummary = showDuration
        ? 'Bilan mensuel de ${formatLocalMonthLabel(summary.month)} : '
              '${formatLongDuration(summary.totalDuration)} au total, '
              '${summary.totalCount} ${_plural(summary.totalCount, 'séance')}'
        : 'Bilan mensuel de ${formatLocalMonthLabel(summary.month)} : '
              '${_countSummary(summary)}';

    return Card(
      key: const Key('monthly-history-card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MonthlyHistoryMonthNavigation(
              month: summary.month,
              canGoNext: canGoNext,
              isCurrentMonth: isCurrentMonth,
              onPrevious: onPrevious,
              onNext: onNext,
              onToday: onToday,
            ),
            Text(
              showDuration
                  ? 'Temps total — ${formatLongDuration(summary.totalDuration)}'
                  : _countSummary(summary),
              key: const Key('monthly-history-total'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Semantics(
              key: const Key('monthly-history-chart-semantics'),
              label: semanticSummary,
              container: true,
              child: SizedBox(
                height: chartHeight,
                child: _MonthlyHistoryChart(
                  summary: summary,
                  today: today,
                  showDuration: showDuration,
                  onOpenWeek: onOpenWeek,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyHistoryChart extends StatelessWidget {
  const _MonthlyHistoryChart({
    required this.summary,
    required this.today,
    required this.showDuration,
    required this.onOpenWeek,
  });

  final MonthlyHistorySummary summary;
  final DateTime today;
  final bool showDuration;
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
            child: _MonthlyWeekBar(
              index: index,
              bucket: summary.weeks[index],
              today: today,
              showDuration: showDuration,
              maximum: maximum,
              onTap: () => onOpenWeek(summary.weeks[index].week),
            ),
          ),
      ],
    );
  }
}

class _MonthlyWeekBar extends StatelessWidget {
  const _MonthlyWeekBar({
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
    final detail = showDuration
        ? '${formatMonthlyBucketPeriod(bucket)} — '
              '${formatLongDuration(bucket.totalDuration)} · '
              '${bucket.totalCount} ${_plural(bucket.totalCount, 'séance')}'
        : '${formatMonthlyBucketPeriod(bucket)} — '
              '${bucket.totalCount} ${_plural(bucket.totalCount, 'séance')} · '
              '${bucket.completedCount} ${_plural(bucket.completedCount, 'terminée')} · '
              '${bucket.incompleteCount} ${_plural(bucket.incompleteCount, 'incomplète')}';
    final semantics = future ? '$detail. Semaine à venir' : detail;
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
                          child: fraction == 0
                              ? Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                )
                              : showDuration
                              ? _DurationValue(index: index)
                              : _CountValue(index: index, bucket: bucket),
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

String _countSummary(MonthlyHistorySummary summary) {
  if (summary.totalCount == 0) return '0 séance';
  return '${summary.totalCount} ${_plural(summary.totalCount, 'séance')} — '
      '${summary.completedCount} '
      '${_plural(summary.completedCount, 'terminée')} · '
      '${summary.incompleteCount} '
      '${_plural(summary.incompleteCount, 'incomplète')}';
}

String _plural(int count, String singular) =>
    count > 1 ? '${singular}s' : singular;
