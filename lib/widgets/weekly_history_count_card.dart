import 'package:flutter/material.dart';

import '../services/weekly_history_aggregation.dart';
import 'weekly_history_count_chart.dart';
import 'weekly_history_day_labels.dart';
import 'weekly_history_week_navigation.dart';

/// Histogramme du nombre quotidien de séances de la semaine sélectionnée.
class WeeklyHistoryCountCard extends StatefulWidget {
  const WeeklyHistoryCountCard({
    super.key,
    required this.summary,
    required this.today,
    required this.canGoNext,
    required this.isCurrentWeek,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final WeeklyHistorySummary summary;
  final DateTime today;
  final bool canGoNext;
  final bool isCurrentWeek;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  State<WeeklyHistoryCountCard> createState() => _WeeklyHistoryCountCardState();
}

class _WeeklyHistoryCountCardState extends State<WeeklyHistoryCountCard> {
  int? _selectedDay;

  @override
  void didUpdateWidget(covariant WeeklyHistoryCountCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.summary.week.hasSameStart(widget.summary.week)) {
      _selectedDay = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maximumChartHeight = widget.isCurrentWeek ? 168.0 : 120.0;
    final chartHeight = (MediaQuery.sizeOf(context).height * 0.3).clamp(
      120.0,
      maximumChartHeight,
    );
    final countSummary = formatWeeklyHistoryCountSummary(widget.summary);

    return Card(
      key: const Key('weekly-history-count-card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WeeklyHistoryWeekNavigation(
              week: widget.summary.week,
              canGoNext: widget.canGoNext,
              isCurrentWeek: widget.isCurrentWeek,
              onPrevious: widget.onPrevious,
              onNext: widget.onNext,
              onToday: widget.onToday,
            ),
            Semantics(
              key: const Key('weekly-count-summary-semantics'),
              label: formatWeeklyHistoryCountSemanticSummary(widget.summary),
              container: true,
              child: ExcludeSemantics(
                child: Text(
                  countSummary,
                  key: const Key('weekly-history-text-summary'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: chartHeight,
              child: WeeklyHistoryCountChart(
                summary: widget.summary,
                today: widget.today,
                onSelectDay: (index) => setState(() => _selectedDay = index),
              ),
            ),
            if (_selectedDay case final selected?) ...[
              const SizedBox(height: 8),
              Text(
                formatWeeklyHistoryCountDayDetail(
                  widget.summary.days[selected],
                ),
                key: const Key('weekly-count-day-detail'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
