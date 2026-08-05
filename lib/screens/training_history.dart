import 'package:flutter/material.dart';

import '../controllers/training_history_controller.dart';
import '../models/training_history_entry.dart';
import '../services/json_prefs_storage.dart';
import '../services/weekly_history_aggregation.dart';
import '../utils/formatters.dart';
import '../utils/snack.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/storage_read_feedback.dart';
import 'training_history_detail.dart';

/// Historique hebdomadaire. Le contrôleur injecté est possédé puis libéré par
/// cet écran ; la composition de l'application lui fournit le stockage réel.
class TrainingHistoryScreen extends StatefulWidget {
  const TrainingHistoryScreen({super.key, required this.controller});

  final TrainingHistoryController controller;

  @override
  State<TrainingHistoryScreen> createState() => _TrainingHistoryScreenState();
}

class _TrainingHistoryScreenState extends State<TrainingHistoryScreen> {
  TrainingHistoryController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(TrainingHistoryEntry entry) async {
    if (_controller.mutationsBlocked) return;

    final bool deleted;
    try {
      deleted = await confirmAndDelete(
        context,
        title: "Supprimer cette séance ?",
        content:
            'Cette action est irréversible. Supprimer "${entry.trainingName}" '
            'du ${formatDateTime(entry.date)} de l\'historique ?',
        onDelete: () => _controller.deleteEntry(entry.id),
      );
    } on StorageMutationBlockedException {
      if (!mounted) return;
      showSnack(
        context,
        "Suppression impossible : certaines données de l'historique n'ont "
        "pas pu être lues.",
      );
      return;
    }

    if (!deleted || !mounted) return;
  }

  Future<void> _openDetail(TrainingHistoryEntry entry) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingHistoryDetailScreen(
          entry: entry,
          allowDelete: !_controller.mutationsBlocked,
          onDelete: () => _controller.deleteEntry(entry.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final status = _controller.status;
        return Scaffold(
          appBar: AppBar(title: const Text("Historique")),
          body: status == TrainingHistoryLoadStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : status == TrainingHistoryLoadStatus.failure
              ? StorageReadErrorView(
                  message: "L'historique enregistré n'a pas pu être lu.",
                  onRetry: _controller.load,
                )
              : _HistoryContent(
                  controller: _controller,
                  storageWarning: status == TrainingHistoryLoadStatus.partial,
                  onOpenDetail: _openDetail,
                  onDelete: _confirmDelete,
                ),
        );
      },
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({
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
    final summary = controller.summary;
    final entries = summary.entries;

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
            child: _WeeklySummaryCard(
              summary: summary,
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
                return _HistoryEntryCard(
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

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({
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
    final completedColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.green.shade300
        : Colors.green.shade700;
    final incompleteColor = Theme.of(context).colorScheme.tertiary;
    final semanticSummary = _semanticSummary(summary);

    return Card(
      key: const Key('weekly-history-summary-card'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 160),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    child: const Text("Aujourd’hui"),
                  ),
                ),
              Semantics(
                key: const Key('weekly-history-chart-semantics'),
                label: semanticSummary,
                container: true,
                child: ExcludeSemantics(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 20,
                      child: summary.totalCount == 0
                          ? ColoredBox(
                              key: const Key('weekly-history-empty-bar'),
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            )
                          : Row(
                              children: [
                                if (summary.completedCount > 0)
                                  Expanded(
                                    flex: summary.completedCount,
                                    child: ColoredBox(
                                      key: const Key(
                                        'weekly-history-completed-bar',
                                      ),
                                      color: completedColor,
                                    ),
                                  ),
                                if (summary.incompleteCount > 0)
                                  Expanded(
                                    flex: summary.incompleteCount,
                                    child: ColoredBox(
                                      key: const Key(
                                        'weekly-history-incomplete-bar',
                                      ),
                                      color: incompleteColor,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _visibleSummary(summary),
                key: const Key('weekly-history-text-summary'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _visibleSummary(WeeklyHistorySummary summary) {
  if (summary.totalCount == 0) return '0 séance';
  return '${summary.totalCount} ${_plural(summary.totalCount, 'séance')} — '
      '${summary.completedCount} '
      '${_plural(summary.completedCount, 'terminée')} · '
      '${summary.incompleteCount} '
      '${_plural(summary.incompleteCount, 'incomplète')}';
}

String _semanticSummary(WeeklyHistorySummary summary) =>
    'Bilan hebdomadaire : ${_visibleSummary(summary)}';

String _plural(int count, String singular) =>
    count > 1 ? '${singular}s' : singular;

class _HistoryEntryCard extends StatelessWidget {
  final TrainingHistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _HistoryEntryCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = entry.status == TrainingSessionStatus.completed;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.incomplete_circle,
                color: isCompleted
                    ? Colors.green
                    : Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.trainingName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDateTime(entry.date),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Durée : ${formatDuration(entry.totalDuration)} · "
                      "${isCompleted ? 'Terminée' : 'Incomplète'}",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: "Supprimer",
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
