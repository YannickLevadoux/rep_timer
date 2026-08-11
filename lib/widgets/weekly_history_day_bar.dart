import 'package:flutter/material.dart';

import '../services/weekly_history_aggregation.dart';
import 'weekly_history_day_labels.dart';

/// Emplacement quotidien commun aux histogrammes hebdomadaires.
class WeeklyHistoryDayBar extends StatelessWidget {
  const WeeklyHistoryDayBar({
    super.key,
    required this.keyPrefix,
    required this.index,
    required this.day,
    required this.today,
    required this.detail,
    required this.value,
    required this.onTap,
  });

  final String keyPrefix;
  final int index;
  final WeeklyHistoryDay day;
  final DateTime today;
  final String detail;
  final Widget value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isToday = _sameDay(day.date, today);
    final isFuture = day.date.isAfter(today);
    final semantics = [
      detail,
      if (isToday) 'Aujourd’hui',
      if (isFuture) 'Jour à venir',
    ].join('. ');

    return Semantics(
      key: Key('$keyPrefix-day-semantics-$index'),
      label: semantics,
      button: true,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          key: Key('$keyPrefix-bar-$index'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                Expanded(child: value),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    weeklyHistoryShortWeekdays[index],
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

/// Valeur verticale alignée en bas, avec le repère commun des jours vides.
class WeeklyHistoryBarValue extends StatelessWidget {
  const WeeklyHistoryBarValue({
    super.key,
    required this.valueKey,
    required this.fraction,
    required this.child,
  });

  final Key valueKey;
  final double fraction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        key: valueKey,
        heightFactor: fraction == 0 ? null : fraction,
        child: fraction == 0
            ? Container(
                width: 22,
                height: 2,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              )
            : SizedBox(
                width: 22,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  child: child,
                ),
              ),
      ),
    );
  }
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
