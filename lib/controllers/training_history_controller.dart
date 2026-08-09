import 'package:flutter/foundation.dart';

import '../models/training_history_entry.dart';
import '../services/json_prefs_storage.dart';
import '../services/monthly_history_aggregation.dart';
import '../services/training_history_storage.dart';
import '../services/weekly_history_aggregation.dart';

typedef HistoryClock = DateTime Function();

enum TrainingHistoryLoadStatus { loading, empty, valid, partial, failure }

enum HistoryPeriod { week, month }

/// Orchestration testable du stockage et de la période affichée.
class TrainingHistoryController extends ChangeNotifier {
  TrainingHistoryController({required this.storage, HistoryClock? now})
    : _now = now ?? DateTime.now,
      _anchorDate = _localDay((now ?? DateTime.now)()) {
    summary = aggregateHistoryWeek(const [], selectedWeek);
    monthlySummary = aggregateHistoryMonth(const [], selectedMonth);
  }

  final TrainingHistoryStore storage;
  final HistoryClock _now;
  DateTime _anchorDate;
  List<TrainingHistoryEntry> _allEntries = const [];
  bool _disposed = false;

  TrainingHistoryLoadStatus status = TrainingHistoryLoadStatus.loading;
  HistoryPeriod period = HistoryPeriod.week;
  late WeeklyHistorySummary summary;
  late MonthlyHistorySummary monthlySummary;

  LocalWeek get currentWeek => LocalWeek.containing(_now());
  LocalMonth get currentMonth => LocalMonth.containing(_now());
  LocalWeek get selectedWeek => LocalWeek.containing(_anchorDate);
  LocalMonth get selectedMonth => LocalMonth.containing(_anchorDate);
  List<TrainingHistoryEntry> get displayedEntries =>
      period == HistoryPeriod.week ? summary.entries : monthlySummary.entries;
  DateTime get today {
    return _localDay(_now());
  }

  bool get canGoNext => selectedWeek.start.isBefore(currentWeek.start);
  bool get isCurrentWeek => selectedWeek.hasSameStart(currentWeek);
  bool get canGoNextMonth => selectedMonth.start.isBefore(currentMonth.start);
  bool get isCurrentMonth => selectedMonth.hasSameStart(currentMonth);
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
    _anchorDate = DateTime(
      _anchorDate.year,
      _anchorDate.month,
      _anchorDate.day - 7,
    );
    _recalculate();
  }

  void showNextWeek() {
    if (!canGoNext) return;
    final candidate = DateTime(
      _anchorDate.year,
      _anchorDate.month,
      _anchorDate.day + 7,
    );
    _anchorDate =
        LocalWeek.containing(candidate).start.isAfter(currentWeek.start)
        ? today
        : candidate;
    _recalculate();
  }

  void showCurrentWeek() {
    _anchorDate = today;
    _recalculate();
  }

  void showPreviousMonth() {
    _anchorDate = _shiftMonth(_anchorDate, -1);
    _recalculate();
  }

  void showNextMonth() {
    if (!canGoNextMonth) return;
    final candidate = _shiftMonth(_anchorDate, 1);
    _anchorDate = LocalMonth.containing(candidate).hasSameStart(currentMonth)
        ? today
        : candidate;
    _recalculate();
  }

  void showCurrentMonth() {
    _anchorDate = today;
    _recalculate();
  }

  void setPeriod(HistoryPeriod value) {
    if (period == value) return;
    period = value;
    _recalculate();
  }

  void showWeek(LocalWeek week) {
    _anchorDate = week.start;
    period = HistoryPeriod.week;
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
    summary = aggregateHistoryWeek(_allEntries, selectedWeek);
    monthlySummary = aggregateHistoryMonth(_allEntries, selectedMonth);
    if (status != TrainingHistoryLoadStatus.loading &&
        status != TrainingHistoryLoadStatus.partial &&
        status != TrainingHistoryLoadStatus.failure) {
      status = displayedEntries.isEmpty
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

DateTime _localDay(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime _shiftMonth(DateTime anchor, int monthDelta) {
  final targetMonthStart = DateTime(anchor.year, anchor.month + monthDelta);
  final lastDay = DateTime(
    targetMonthStart.year,
    targetMonthStart.month + 1,
    0,
  ).day;
  final day = anchor.day > lastDay ? lastDay : anchor.day;
  return DateTime(targetMonthStart.year, targetMonthStart.month, day);
}
