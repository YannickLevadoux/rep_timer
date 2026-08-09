import 'package:flutter/material.dart';

import '../controllers/training_history_controller.dart';
import '../models/training_history_entry.dart';
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
    final entries = controller.summary.entries;

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
                Text('Métrique', style: Theme.of(context).textTheme.labelLarge),
                DropdownButton<HistoryMetric>(
                  key: const Key('history-metric-selector'),
                  value: _metric,
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
                  onChanged: (metric) {
                    if (metric == null) return;
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
            child: _metric == HistoryMetric.sessionCount
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
              'Séances de la semaine — ${entries.length}',
              key: const Key('weekly-history-list-title'),
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
