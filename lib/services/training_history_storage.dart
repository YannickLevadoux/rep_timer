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

  Future<StorageReadResult<List<TrainingHistoryEntry>>> loadHistory() =>
      _storage.loadList();

  Future<void> addEntry(TrainingHistoryEntry entry) async {
    final history = await _healthyHistoryForMutation();
    history.add(entry);
    await _storage.saveList(history);
  }

  Future<void> deleteEntry(String id) async {
    final history = await _healthyHistoryForMutation();
    history.removeWhere((entry) => entry.id == id);
    await _storage.saveList(history);
  }

  Future<List<TrainingHistoryEntry>> _healthyHistoryForMutation() async {
    final result = await loadHistory();
    return switch (result) {
      StorageNoData<List<TrainingHistoryEntry>>() => <TrainingHistoryEntry>[],
      StorageReadSuccess<List<TrainingHistoryEntry>>(:final data) => List.of(
        data,
      ),
      StorageReadPartial<List<TrainingHistoryEntry>>() =>
        throw const StorageMutationBlockedException(
          StorageBlockedState.partial,
        ),
      StorageReadFailure<List<TrainingHistoryEntry>>(:final error) =>
        throw StorageMutationBlockedException(
          StorageBlockedState.unreadable,
          readError: error,
        ),
    };
  }
}
