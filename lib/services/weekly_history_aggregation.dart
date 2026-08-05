import '../models/training_history_entry.dart';

/// Bornes calendaires locales d'une semaine, du lundi inclus au lundi suivant
/// exclu.
class LocalWeek {
  const LocalWeek({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  factory LocalWeek.containing(DateTime date) {
    final local = date.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final start = DateTime(day.year, day.month, day.day - (day.weekday - 1));
    return LocalWeek(
      start: start,
      // Construction calendaire volontaire : ajouter 7 x 24 h serait faux
      // pour certaines semaines comportant un changement d'heure.
      end: DateTime(start.year, start.month, start.day + 7),
    );
  }

  LocalWeek previous() =>
      LocalWeek.containing(DateTime(start.year, start.month, start.day - 7));

  LocalWeek next() =>
      LocalWeek.containing(DateTime(start.year, start.month, start.day + 7));

  bool contains(DateTime date) {
    final local = date.toLocal();
    return !local.isBefore(start) && local.isBefore(end);
  }

  bool hasSameStart(LocalWeek other) => start == other.start;
}

/// État hebdomadaire directement exploitable par la présentation.
class WeeklyHistorySummary {
  const WeeklyHistorySummary({
    required this.week,
    required this.entries,
    required this.completedCount,
    required this.incompleteCount,
  });

  final LocalWeek week;
  final List<TrainingHistoryEntry> entries;
  final int completedCount;
  final int incompleteCount;

  int get totalCount => entries.length;
}

/// Agrégation pure de l'historique pour une semaine calendaire locale.
WeeklyHistorySummary aggregateHistoryWeek(
  Iterable<TrainingHistoryEntry> allEntries,
  LocalWeek week,
) {
  final entries =
      allEntries.where((entry) => week.contains(entry.date)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  final completedCount = entries
      .where((entry) => entry.status == TrainingSessionStatus.completed)
      .length;

  return WeeklyHistorySummary(
    week: week,
    entries: List.unmodifiable(entries),
    completedCount: completedCount,
    incompleteCount: entries.length - completedCount,
  );
}

/// Libellé français compact de la période, sans dépendance à Flutter.
String formatLocalWeekLabel(LocalWeek week) {
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  final first = week.start;
  final last = DateTime(week.end.year, week.end.month, week.end.day - 1);
  if (first.year != last.year) {
    return '${first.day} ${months[first.month - 1]} ${first.year}–'
        '${last.day} ${months[last.month - 1]} ${last.year}';
  }
  if (first.month != last.month) {
    return '${first.day} ${months[first.month - 1]}–'
        '${last.day} ${months[last.month - 1]} ${last.year}';
  }
  return '${first.day}–${last.day} ${months[first.month - 1]} ${first.year}';
}
