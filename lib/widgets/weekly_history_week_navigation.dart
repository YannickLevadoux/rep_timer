import 'package:flutter/material.dart';

import '../services/weekly_history_aggregation.dart';

/// Navigation commune aux différentes métriques de l'historique hebdomadaire.
class WeeklyHistoryWeekNavigation extends StatelessWidget {
  const WeeklyHistoryWeekNavigation({
    super.key,
    required this.week,
    required this.canGoNext,
    required this.isCurrentWeek,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final LocalWeek week;
  final bool canGoNext;
  final bool isCurrentWeek;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          key: const Key('previous-week-button'),
          tooltip: 'Semaine précédente',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            formatLocalWeekLabel(week),
            key: const Key('selected-week-label'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Semantics(
          label: "Revenir à aujourd'hui",
          button: true,
          enabled: !isCurrentWeek,
          excludeSemantics: true,
          child: IconButton(
            key: const Key('today-button'),
            tooltip: "Revenir à aujourd'hui",
            onPressed: isCurrentWeek ? null : onToday,
            icon: const Icon(Icons.today),
          ),
        ),
        IconButton(
          key: const Key('next-week-button'),
          tooltip: 'Semaine suivante',
          onPressed: canGoNext ? onNext : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
