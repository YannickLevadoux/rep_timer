import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/weekly_history_aggregation.dart';
import '../utils/formatters.dart';

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
            _WeekNavigation(
              summary: widget.summary,
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
              child: _DurationChart(
                summary: widget.summary,
                today: widget.today,
                onSelectDay: (index) => setState(() => _selectedDay = index),
              ),
            ),
            if (_selectedDay case final selected?) ...[
              const SizedBox(height: 8),
              Text(
                _dayDetail(widget.summary.days[selected]),
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

class _WeekNavigation extends StatelessWidget {
  const _WeekNavigation({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              key: const Key('previous-week-button'),
              tooltip: 'Semaine précédente',
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                formatLocalWeekLabel(summary.week),
                key: const Key('selected-week-label'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              key: const Key('next-week-button'),
              tooltip: 'Semaine suivante',
              onPressed: canGoNext ? onNext : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        if (!isCurrentWeek)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('today-button'),
              onPressed: onToday,
              child: const Text('Aujourd’hui'),
            ),
          ),
      ],
    );
  }
}

class _DurationChart extends StatelessWidget {
  const _DurationChart({
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
      _dayDetail(day),
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
                    builder: (context, constraints) {
                      final ratio = maximumDurationInMicroseconds == 0
                          ? 0.0
                          : day.duration.inMicroseconds /
                                maximumDurationInMicroseconds;
                      final height = constraints.maxHeight * ratio;
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
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _shortWeekdays[index],
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
}

const _shortWeekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
const _longWeekdays = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];
const _months = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

String _dayDetail(WeeklyHistoryDay day) {
  final sessions = day.sessionCount > 1 ? 'séances' : 'séance';
  return '${_longWeekdays[day.date.weekday - 1]} ${day.date.day} '
      '${_months[day.date.month - 1]} — ${formatLongDuration(day.duration)} '
      '· ${day.sessionCount} $sessions';
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
