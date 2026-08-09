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
    required this.days,
    required this.totalDuration,
  });

  final LocalWeek week;
  final List<TrainingHistoryEntry> entries;
  final int completedCount;
  final int incompleteCount;
  final List<WeeklyHistoryDay> days;
  final Duration totalDuration;

  int get totalCount => entries.length;
}

/// Agrégat d'une journée calendaire locale de la semaine affichée.
class WeeklyHistoryDay {
  const WeeklyHistoryDay({
    required this.date,
    required this.duration,
    required this.sessionCount,
  });

  final DateTime date;
  final Duration duration;
  final int sessionCount;
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
  final durationsInMicroseconds = List<int>.filled(7, 0);
  final sessionCounts = List<int>.filled(7, 0);

  for (final entry in entries) {
    final local = entry.date.toLocal();
    final dayIndex = _dayIndex(
      week,
      DateTime(local.year, local.month, local.day),
    );
    // Une donnée historique invalide ne doit ni inverser une barre ni réduire
    // le total. La valeur persistée reste volontairement inchangée.
    final duration = entry.totalDuration.isNegative
        ? Duration.zero
        : entry.totalDuration;
    durationsInMicroseconds[dayIndex] += duration.inMicroseconds;
    sessionCounts[dayIndex]++;
  }

  final days = List<WeeklyHistoryDay>.generate(7, (index) {
    return WeeklyHistoryDay(
      date: DateTime(week.start.year, week.start.month, week.start.day + index),
      duration: Duration(microseconds: durationsInMicroseconds[index]),
      sessionCount: sessionCounts[index],
    );
  });
  final totalMicroseconds = durationsInMicroseconds.fold<int>(
    0,
    (total, duration) => total + duration,
  );

  return WeeklyHistorySummary(
    week: week,
    entries: List.unmodifiable(entries),
    completedCount: completedCount,
    incompleteCount: entries.length - completedCount,
    days: List.unmodifiable(days),
    totalDuration: Duration(microseconds: totalMicroseconds),
  );
}

int _dayIndex(LocalWeek week, DateTime localDay) {
  for (var index = 0; index < 7; index++) {
    final candidate = DateTime(
      week.start.year,
      week.start.month,
      week.start.day + index,
    );
    if (candidate.year == localDay.year &&
        candidate.month == localDay.month &&
        candidate.day == localDay.day) {
      return index;
    }
  }
  // Les entrées ont déjà été filtrées par les bornes de la semaine.
  throw StateError('Jour absent de la semaine sélectionnée : $localDay');
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
