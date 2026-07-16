import '../models/training_history_entry.dart';
import 'json_prefs_storage.dart';

/// Sauvegarde locale de l'historique des séances effectuées (persistée en
/// JSON via SharedPreferences, même mécanisme que TrainingStorage).
class TrainingHistoryStorage {
  static const _storageKey = 'training_history';

  final JsonListStorage<TrainingHistoryEntry> _storage =
      JsonListStorage<TrainingHistoryEntry>(
        storageKey: _storageKey,
        fromJson: TrainingHistoryEntry.fromJson,
        toJson: (e) => e.toJson(),
      );

  Future<List<TrainingHistoryEntry>> loadHistory() => _storage.loadList();

  Future<void> addEntry(TrainingHistoryEntry entry) async {
    final history = await loadHistory();
    history.add(entry);
    await _storage.saveList(history);
  }

  Future<void> deleteEntry(String id) async {
    final history = await loadHistory();
    history.removeWhere((entry) => entry.id == id);
    await _storage.saveList(history);
  }
}
