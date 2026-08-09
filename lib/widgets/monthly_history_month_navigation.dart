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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              key: const Key('next-month-button'),
              tooltip: 'Mois suivant',
              onPressed: canGoNext ? onNext : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        if (!isCurrentMonth)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('month-today-button'),
              onPressed: onToday,
              child: const Text('Aujourd’hui'),
            ),
          ),
      ],
    );
  }
}
