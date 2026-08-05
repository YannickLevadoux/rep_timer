import 'package:flutter/foundation.dart';

import '../models/training_history_entry.dart';
import '../services/json_prefs_storage.dart';
import '../services/training_history_storage.dart';
import '../services/weekly_history_aggregation.dart';

typedef HistoryClock = DateTime Function();

enum TrainingHistoryLoadStatus { loading, empty, valid, partial, failure }

/// Orchestration testable du stockage et de la période affichée.
class TrainingHistoryController extends ChangeNotifier {
  TrainingHistoryController({required this.storage, HistoryClock? now})
    : _now = now ?? DateTime.now,
      _selectedWeek = LocalWeek.containing((now ?? DateTime.now)()) {
    summary = aggregateHistoryWeek(const [], _selectedWeek);
  }

  final TrainingHistoryStore storage;
  final HistoryClock _now;
  LocalWeek _selectedWeek;
  List<TrainingHistoryEntry> _allEntries = const [];
  bool _disposed = false;

  TrainingHistoryLoadStatus status = TrainingHistoryLoadStatus.loading;
  late WeeklyHistorySummary summary;

  LocalWeek get currentWeek => LocalWeek.containing(_now());
  bool get canGoNext => _selectedWeek.start.isBefore(currentWeek.start);
  bool get isCurrentWeek => _selectedWeek.hasSameStart(currentWeek);
  bool get mutationsBlocked =>
      status == TrainingHistoryLoadStatus.partial ||
      status == TrainingHistoryLoadStatus.failure;

  Future<void> load() async {
    status = TrainingHistoryLoadStatus.loading;
    _notify();
    final result = await storage.loadHistory();
    if (_disposed) return;

    switch (result) {
      case StorageNoData<List<TrainingHistoryEntry>>():
        _allEntries = const [];
        status = TrainingHistoryLoadStatus.empty;
      case StorageReadSuccess<List<TrainingHistoryEntry>>(:final data):
        _allEntries = List.of(data);
        status = data.isEmpty
            ? TrainingHistoryLoadStatus.empty
            : TrainingHistoryLoadStatus.valid;
      case StorageReadPartial<List<TrainingHistoryEntry>>(:final data):
        _allEntries = List.of(data);
        status = TrainingHistoryLoadStatus.partial;
      case StorageReadFailure<List<TrainingHistoryEntry>>():
        _allEntries = const [];
        status = TrainingHistoryLoadStatus.failure;
    }
    _recalculate();
  }

  void showPreviousWeek() {
    _selectedWeek = _selectedWeek.previous();
    _recalculate();
  }

  void showNextWeek() {
    if (!canGoNext) return;
    final next = _selectedWeek.next();
    _selectedWeek = next.start.isAfter(currentWeek.start) ? currentWeek : next;
    _recalculate();
  }

  void showCurrentWeek() {
    _selectedWeek = currentWeek;
    _recalculate();
  }

  Future<void> deleteEntry(String id) async {
    if (mutationsBlocked) {
      throw const StorageMutationBlockedException(StorageBlockedState.partial);
    }
    try {
      await storage.deleteEntry(id);
    } on StorageMutationBlockedException {
      status = TrainingHistoryLoadStatus.partial;
      _notify();
      rethrow;
    }
    _allEntries = _allEntries.where((entry) => entry.id != id).toList();
    if (_allEntries.isEmpty) status = TrainingHistoryLoadStatus.empty;
    _recalculate();
  }

  void _recalculate() {
    summary = aggregateHistoryWeek(_allEntries, _selectedWeek);
    if (status != TrainingHistoryLoadStatus.loading &&
        status != TrainingHistoryLoadStatus.partial &&
        status != TrainingHistoryLoadStatus.failure) {
      status = summary.entries.isEmpty
          ? TrainingHistoryLoadStatus.empty
          : TrainingHistoryLoadStatus.valid;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
