import 'package:flutter/material.dart';

import '../controllers/training_history_controller.dart';
import '../models/training_history_entry.dart';
import 'monthly_history_card.dart';
import 'storage_read_feedback.dart';
import 'training_history_entry_card.dart';
import 'training_history_selectors.dart';
import 'weekly_history_duration_card.dart';
import 'weekly_history_summary_card.dart';

export 'training_history_selectors.dart' show HistoryMetric;

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
            child: TrainingHistorySelectors(
              controller: controller,
              metric: _metric,
              onMetricChanged: (metric) {
                setState(() => _metric = metric);
              },
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
