import 'package:flutter/material.dart';

import '../models/training_history_entry.dart';
import '../services/json_prefs_storage.dart';
import '../services/training_history_storage.dart';
import '../utils/formatters.dart';
import '../utils/snack.dart';
import '../widgets/dialogs/confirm_dialog.dart';
import '../widgets/storage_read_feedback.dart';
import 'training_history_detail.dart';

/// Écran listant les séances effectuées, du plus récent au plus ancien.
/// Affiche seulement les 5 plus récentes au départ, avec la possibilité
/// de tout charger via "Tout Visualiser".
class TrainingHistoryScreen extends StatefulWidget {
  const TrainingHistoryScreen({super.key});

  @override
  State<TrainingHistoryScreen> createState() => _TrainingHistoryScreenState();
}

class _TrainingHistoryScreenState extends State<TrainingHistoryScreen> {
  static const _initialLimit = 5;

  final TrainingHistoryStorage _storage = TrainingHistoryStorage();

  List<TrainingHistoryEntry> _allEntries = [];
  bool _loading = true;
  bool _showAll = false;
  bool _storageWarning = false;
  bool _storageFailure = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final result = await _storage.loadHistory();
    final List<TrainingHistoryEntry> entries;
    switch (result) {
      case StorageNoData<List<TrainingHistoryEntry>>():
        entries = <TrainingHistoryEntry>[];
      case StorageReadSuccess<List<TrainingHistoryEntry>>(:final data):
        entries = data;
      case StorageReadPartial<List<TrainingHistoryEntry>>(:final data):
        entries = data;
      case StorageReadFailure<List<TrainingHistoryEntry>>():
        if (!mounted) return;
        setState(() {
          _allEntries = <TrainingHistoryEntry>[];
          _storageWarning = false;
          _storageFailure = true;
          _loading = false;
        });
        return;
    }

    // Plus récent au plus ancien.
    entries.sort((a, b) => b.date.compareTo(a.date));

    if (!mounted) return;
    setState(() {
      _allEntries = entries;
      _storageWarning =
          result is StorageReadPartial<List<TrainingHistoryEntry>>;
      _storageFailure = false;
      _loading = false;
    });
  }

  Future<void> _confirmDelete(TrainingHistoryEntry entry) async {
    if (_storageWarning || _storageFailure) return;

    final bool deleted;
    try {
      deleted = await confirmAndDelete(
        context,
        title: "Supprimer cette séance ?",
        content:
            'Cette action est irréversible. Supprimer "${entry.trainingName}" '
            'du ${formatDateTime(entry.date)} de l\'historique ?',
        onDelete: () => _storage.deleteEntry(entry.id),
      );
    } on StorageMutationBlockedException {
      if (!mounted) return;
      setState(() => _storageWarning = true);
      showSnack(
        context,
        "Suppression impossible : certaines données de l'historique n'ont "
        "pas pu être lues.",
      );
      return;
    }

    if (!deleted || !mounted) return;
    setState(() {
      _allEntries.removeWhere((e) => e.id == entry.id);
    });
  }

  Future<void> _openDetail(TrainingHistoryEntry entry) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingHistoryDetailScreen(
          entry: entry,
          allowDelete: !_storageWarning && !_storageFailure,
        ),
      ),
    );

    if (deleted == true) {
      setState(() {
        _allEntries.removeWhere((e) => e.id == entry.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedEntries = _showAll
        ? _allEntries
        : _allEntries.take(_initialLimit).toList();
    final hasMore = !_showAll && _allEntries.length > _initialLimit;

    return Scaffold(
      appBar: AppBar(title: const Text("Historique")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _storageFailure
          ? StorageReadErrorView(
              message: "L'historique enregistré n'a pas pu être lu.",
              onRetry: _loadHistory,
            )
          : Column(
              children: [
                if (_storageWarning)
                  const StorageReadWarningBanner(
                    message:
                        "Certaines séances de l'historique n'ont pas pu être "
                        "lues. La suppression est désactivée pour protéger "
                        "les données.",
                  ),
                Expanded(
                  child: _allEntries.isEmpty
                      ? const Center(
                          child: Text("Aucune séance effectuée pour l'instant"),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: displayedEntries.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final entry = displayedEntries[index];
                            return _HistoryEntryCard(
                              entry: entry,
                              onTap: () => _openDetail(entry),
                              onDelete: _storageWarning
                                  ? null
                                  : () => _confirmDelete(entry),
                            );
                          },
                        ),
                ),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _showAll = true),
                        child: const Text("Tout Visualiser"),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

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
