import 'package:flutter/material.dart';

import '../services/weekly_history_aggregation.dart';
import '../utils/formatters.dart';
import 'weekly_history_day_labels.dart';
import 'weekly_history_duration_chart.dart';
import 'weekly_history_week_navigation.dart';

/// Histogramme des durées quotidiennes de la semaine sélectionnée.
class WeeklyHistoryDurationCard extends StatefulWidget {
  const WeeklyHistoryDurationCard({
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
  State<WeeklyHistoryDurationCard> createState() =>
      _WeeklyHistoryDurationCardState();
}

class _WeeklyHistoryDurationCardState extends State<WeeklyHistoryDurationCard> {
  int? _selectedDay;

  @override
  void didUpdateWidget(covariant WeeklyHistoryDurationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.summary.week.hasSameStart(widget.summary.week)) {
      _selectedDay = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartHeight = (MediaQuery.sizeOf(context).height * 0.3).clamp(
      120.0,
      168.0,
    );

    return Card(
      key: const Key('weekly-history-duration-card'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: WeeklyHistoryWeekNavigation(
              week: widget.summary.week,
              canGoNext: widget.canGoNext,
              isCurrentWeek: widget.isCurrentWeek,
              onPrevious: widget.onPrevious,
              onNext: widget.onNext,
              onToday: widget.onToday,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Temps total — ${formatLongDuration(widget.summary.totalDuration)}',
                  key: const Key('weekly-duration-total'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: chartHeight,
                  child: WeeklyHistoryDurationChart(
                    summary: widget.summary,
                    today: widget.today,
                    onSelectDay: (index) =>
                        setState(() => _selectedDay = index),
                  ),
                ),
                if (_selectedDay case final selected?) ...[
                  const SizedBox(height: 8),
                  Text(
                    formatWeeklyHistoryDayDetail(widget.summary.days[selected]),
                    key: const Key('weekly-duration-day-detail'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
