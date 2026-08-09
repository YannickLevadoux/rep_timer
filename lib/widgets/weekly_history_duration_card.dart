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
    // La ligne « Aujourd’hui » des semaines passées prend la place libérée en
    // réduisant le graphe, afin de garder la carte proche de 280 px.
    final maximumChartHeight = widget.isCurrentWeek ? 168.0 : 120.0;
    final chartHeight = (MediaQuery.sizeOf(context).height * 0.3).clamp(
      120.0,
      maximumChartHeight,
    );

    return Card(
      key: const Key('weekly-history-duration-card'),
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
                onSelectDay: (index) => setState(() => _selectedDay = index),
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
    );
  }
}
