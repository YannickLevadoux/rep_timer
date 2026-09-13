import 'package:flutter/material.dart';

import '../services/monthly_history_aggregation.dart';
import '../services/weekly_history_aggregation.dart';
import '../utils/formatters.dart';
import 'monthly_history_chart.dart';
import 'monthly_history_duration_label.dart';
import 'monthly_history_labels.dart';
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
    final baseChartHeight = (MediaQuery.sizeOf(context).height * 0.24).clamp(
      128.0,
      168.0,
    );

    return Card(
      key: const Key('monthly-history-card'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: MonthlyHistoryMonthNavigation(
              month: summary.month,
              canGoNext: canGoNext,
              isCurrentMonth: isCurrentMonth,
              onPrevious: onPrevious,
              onNext: onNext,
              onToday: onToday,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  showDuration
                      ? 'Temps total — ${formatLongDuration(summary.totalDuration)}'
                      : formatMonthlyCountSummary(summary),
                  key: const Key('monthly-history-total'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final durationLabelHeight = _durationLabelHeight(
                      context,
                      constraints.maxWidth,
                    );
                    return Semantics(
                      key: const Key('monthly-history-chart-semantics'),
                      label: formatMonthlySemanticSummary(
                        summary,
                        showDuration: showDuration,
                      ),
                      container: true,
                      child: SizedBox(
                        height:
                            baseChartHeight +
                            (durationLabelHeight == 0
                                ? 0
                                : durationLabelHeight + 4),
                        child: MonthlyHistoryChart(
                          summary: summary,
                          today: today,
                          showDuration: showDuration,
                          durationLabelHeight: durationLabelHeight,
                          onOpenWeek: onOpenWeek,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _durationLabelHeight(BuildContext context, double chartWidth) {
    if (!showDuration || summary.weeks.isEmpty) return 0;
    final labelWidth = chartWidth / summary.weeks.length - 6;
    var maximum = 0.0;
    for (final bucket in summary.weeks) {
      if (bucket.totalDuration == Duration.zero) continue;
      final height = monthlyHistoryDurationLabelHeight(
        context,
        bucket.totalDuration,
        maxWidth: labelWidth,
      );
      if (height > maximum) maximum = height;
    }
    return maximum;
  }
}
