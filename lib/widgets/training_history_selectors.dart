import 'package:flutter/material.dart';

import '../controllers/training_history_controller.dart';

enum HistoryMetric { sessionCount, timeSpent }

class TrainingHistorySelectors extends StatelessWidget {
  const TrainingHistorySelectors({
    super.key,
    required this.controller,
    required this.metric,
    required this.onMetricChanged,
  });

  final TrainingHistoryController controller;
  final HistoryMetric metric;
  final ValueChanged<HistoryMetric> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    final period = _PeriodSelector(controller: controller);
    final metricSelector = _MetricSelector(
      metric: metric,
      onChanged: onMetricChanged,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        if (constraints.maxWidth < 360 || textScale > 1.5) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [period, const SizedBox(height: 12), metricSelector],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: period),
            const SizedBox(width: 16),
            Expanded(child: metricSelector),
          ],
        );
      },
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.controller});

  final TrainingHistoryController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Période', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        SegmentedButton<HistoryPeriod>(
          key: const Key('history-period-selector'),
          segments: const [
            ButtonSegment(
              value: HistoryPeriod.week,
              label: FittedBox(child: Text('Semaine')),
            ),
            ButtonSegment(
              value: HistoryPeriod.month,
              label: FittedBox(child: Text('Mois')),
            ),
          ],
          selected: {controller.period},
          onSelectionChanged: (selection) {
            controller.setPeriod(selection.single);
          },
          expandedInsets: EdgeInsets.zero,
          showSelectedIcon: false,
        ),
      ],
    );
  }
}

class _MetricSelector extends StatelessWidget {
  const _MetricSelector({required this.metric, required this.onChanged});

  final HistoryMetric metric;
  final ValueChanged<HistoryMetric> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Métrique', style: Theme.of(context).textTheme.labelLarge),
        DropdownButton<HistoryMetric>(
          key: const Key('history-metric-selector'),
          value: metric,
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: HistoryMetric.sessionCount,
              child: Text('Nombre de séances'),
            ),
            DropdownMenuItem(
              value: HistoryMetric.timeSpent,
              child: Text('Temps passé'),
            ),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}
