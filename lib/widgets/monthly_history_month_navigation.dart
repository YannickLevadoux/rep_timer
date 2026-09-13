import 'package:flutter/material.dart';

import '../services/monthly_history_aggregation.dart';

class MonthlyHistoryMonthNavigation extends StatelessWidget {
  const MonthlyHistoryMonthNavigation({
    super.key,
    required this.month,
    required this.canGoNext,
    required this.isCurrentMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final LocalMonth month;
  final bool canGoNext;
  final bool isCurrentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          key: const Key('previous-month-button'),
          tooltip: 'Mois précédent',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            formatLocalMonthLabel(month),
            key: const Key('selected-month-label'),
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
          enabled: !isCurrentMonth,
          excludeSemantics: true,
          child: IconButton(
            key: const Key('month-today-button'),
            tooltip: "Revenir à aujourd'hui",
            onPressed: isCurrentMonth ? null : onToday,
            icon: const Icon(Icons.today),
          ),
        ),
        IconButton(
          key: const Key('next-month-button'),
          tooltip: 'Mois suivant',
          onPressed: canGoNext ? onNext : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
