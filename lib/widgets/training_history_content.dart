import 'package:flutter/material.dart';

import '../controllers/training_history_controller.dart';
import '../models/training_history_entry.dart';
import 'monthly_history_card.dart';
import 'storage_read_feedback.dart';
import 'training_history_entry_card.dart';
import 'weekly_history_duration_card.dart';
import 'weekly_history_summary_card.dart';

enum HistoryMetric { sessionCount, timeSpent }

/// Contenu défilable de l'historique, piloté uniquement par son contrôleur et
/// ses actions de navigation.
class TrainingHistoryContent extends StatefulWidget {
  const TrainingHistoryContent({
    super.key,
    required this.controller,
    required this.storageWarning,
    required this.onOpenDetail,
    required this.onDelete,
  });

  final TrainingHistoryController controller;
  final bool storageWarning;
  final ValueChanged<TrainingHistoryEntry> onOpenDetail;
  final ValueChanged<TrainingHistoryEntry> onDelete;

  @override
  State<TrainingHistoryContent> createState() => _TrainingHistoryContentState();
}

class _TrainingHistoryContentState extends State<TrainingHistoryContent> {
  HistoryMetric _metric = HistoryMetric.sessionCount;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final entries = controller.displayedEntries;
    final isMonthly = controller.period == HistoryPeriod.month;

    return CustomScrollView(
      slivers: [
        if (widget.storageWarning)
          const SliverToBoxAdapter(
            child: StorageReadWarningBanner(
              message:
                  "Certaines séances de l'historique n'ont pas pu être lues. "
                  "Les statistiques peuvent être incomplètes et la suppression "
                  "est désactivée pour protéger les données.",
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HistorySelectors(
                  controller: controller,
                  metric: _metric,
                  onMetricChanged: (metric) {
                    setState(() => _metric = metric);
                  },
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          sliver: SliverToBoxAdapter(
            child: isMonthly
                ? MonthlyHistoryCard(
                    summary: controller.monthlySummary,
                    today: controller.today,
                    showDuration: _metric == HistoryMetric.timeSpent,
                    canGoNext: controller.canGoNextMonth,
                    isCurrentMonth: controller.isCurrentMonth,
                    onPrevious: controller.showPreviousMonth,
                    onNext: controller.showNextMonth,
                    onToday: controller.showCurrentMonth,
                    onOpenWeek: controller.showWeek,
                  )
                : _metric == HistoryMetric.sessionCount
                ? WeeklyHistorySummaryCard(
                    summary: controller.summary,
                    canGoNext: controller.canGoNext,
                    isCurrentWeek: controller.isCurrentWeek,
                    onPrevious: controller.showPreviousWeek,
                    onNext: controller.showNextWeek,
                    onToday: controller.showCurrentWeek,
                  )
                : WeeklyHistoryDurationCard(
                    summary: controller.summary,
                    today: controller.today,
                    canGoNext: controller.canGoNext,
                    isCurrentWeek: controller.isCurrentWeek,
                    onPrevious: controller.showPreviousWeek,
                    onNext: controller.showNextWeek,
                    onToday: controller.showCurrentWeek,
                  ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              '${isMonthly ? 'Séances du mois' : 'Séances de la semaine'} — '
              '${entries.length}',
              key: Key(
                isMonthly
                    ? 'monthly-history-list-title'
                    : 'weekly-history-list-title',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        if (entries.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 48),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Aucune séance sur cette période',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            sliver: SliverList.separated(
              itemCount: entries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return TrainingHistoryEntryCard(
                  entry: entry,
                  onTap: () => widget.onOpenDetail(entry),
                  onDelete: widget.storageWarning
                      ? null
                      : () => widget.onDelete(entry),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _HistorySelectors extends StatelessWidget {
  const _HistorySelectors({
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
