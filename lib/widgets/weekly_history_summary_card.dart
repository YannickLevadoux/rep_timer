import 'package:flutter/material.dart';

import '../services/weekly_history_aggregation.dart';
import '../utils/history_status_colors.dart';
import 'weekly_history_week_navigation.dart';

class WeeklyHistorySummaryCard extends StatelessWidget {
  const WeeklyHistorySummaryCard({
    super.key,
    required this.summary,
    required this.canGoNext,
    required this.isCurrentWeek,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final WeeklyHistorySummary summary;
  final bool canGoNext;
  final bool isCurrentWeek;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final completedColor = completedHistoryColor(context);
    final incompleteColor = incompleteHistoryColor(context);

    return Card(
      key: const Key('weekly-history-summary-card'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 160),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WeeklyHistoryWeekNavigation(
                week: summary.week,
                canGoNext: canGoNext,
                isCurrentWeek: isCurrentWeek,
                onPrevious: onPrevious,
                onNext: onNext,
                onToday: onToday,
              ),
              Semantics(
                key: const Key('weekly-history-chart-semantics'),
                label: _semanticSummary(summary),
                container: true,
                child: ExcludeSemantics(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 20,
                      child: summary.totalCount == 0
                          ? ColoredBox(
                              key: const Key('weekly-history-empty-bar'),
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            )
                          : _WeeklyStackedBar(
                              completedCount: summary.completedCount,
                              incompleteCount: summary.incompleteCount,
                              completedColor: completedColor,
                              incompleteColor: incompleteColor,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _visibleSummary(summary),
                key: const Key('weekly-history-text-summary'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyStackedBar extends StatelessWidget {
  const _WeeklyStackedBar({
    required this.completedCount,
    required this.incompleteCount,
    required this.completedColor,
    required this.incompleteColor,
  });

  final int completedCount;
  final int incompleteCount;
  final Color completedColor;
  final Color incompleteColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (completedCount > 0)
          Expanded(
            flex: completedCount,
            child: ColoredBox(
              key: const Key('weekly-history-completed-bar'),
              color: completedColor,
            ),
          ),
        if (incompleteCount > 0)
          Expanded(
            flex: incompleteCount,
            child: ColoredBox(
              key: const Key('weekly-history-incomplete-bar'),
              color: incompleteColor,
            ),
          ),
      ],
    );
  }
}

String _visibleSummary(WeeklyHistorySummary summary) {
  if (summary.totalCount == 0) return '0 séance';
  return '${summary.totalCount} ${_plural(summary.totalCount, 'séance')} — '
      '${summary.completedCount} '
      '${_plural(summary.completedCount, 'terminée')} · '
      '${summary.incompleteCount} '
      '${_plural(summary.incompleteCount, 'incomplète')}';
}

String _semanticSummary(WeeklyHistorySummary summary) =>
    'Bilan hebdomadaire : ${_visibleSummary(summary)}';

String _plural(int count, String singular) =>
    count > 1 ? '${singular}s' : singular;
