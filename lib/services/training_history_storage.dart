import '../models/training_history_entry.dart';
import 'json_prefs_storage.dart';

/// Contrat minimal utilisé par l'historique pour lire et supprimer des séances.
/// Il permet au contrôleur d'être testé sans dépendre de SharedPreferences.
abstract interface class TrainingHistoryStore {
  Future<StorageReadResult<List<TrainingHistoryEntry>>> loadHistory();

  Future<void> deleteEntry(String id);
}

/// Sauvegarde locale de l'historique des séances effectuées (persistée en
/// JSON via SharedPreferences, même mécanisme que TrainingStorage).
class TrainingHistoryStorage implements TrainingHistoryStore {
  static const storageKey = 'training_history';

  final JsonListStorage<TrainingHistoryEntry> _storage =
      JsonListStorage<TrainingHistoryEntry>(
        storageKey: storageKey,
        fromJson: TrainingHistoryEntry.fromJson,
        toJson: (e) => e.toJson(),
      );

  @override
  Future<StorageReadResult<List<TrainingHistoryEntry>>> loadHistory() =>
      _storage.loadList();

  Future<void> addEntry(TrainingHistoryEntry entry) async {
    final history = await _healthyHistoryForMutation();
    history.add(entry);
    await _storage.saveList(history);
  }

  @override
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
