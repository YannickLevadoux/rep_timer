import 'package:flutter/material.dart';

import '../controllers/training_history_controller.dart';
import '../models/training_history_entry.dart';
import 'storage_read_feedback.dart';
import 'training_history_entry_card.dart';
import 'weekly_history_summary_card.dart';

/// Contenu défilable de l'historique, piloté uniquement par son contrôleur et
/// ses actions de navigation.
class TrainingHistoryContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final entries = controller.summary.entries;

    return CustomScrollView(
      slivers: [
        if (storageWarning)
          const SliverToBoxAdapter(
            child: StorageReadWarningBanner(
              message:
                  "Certaines séances de l'historique n'ont pas pu être lues. "
                  "Les statistiques peuvent être incomplètes et la suppression "
                  "est désactivée pour protéger les données.",
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          sliver: SliverToBoxAdapter(
            child: WeeklyHistorySummaryCard(
              summary: controller.summary,
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
                  onTap: () => onOpenDetail(entry),
                  onDelete: storageWarning ? null : () => onDelete(entry),
                );
              },
            ),
          ),
      ],
    );
  }
}
