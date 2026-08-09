import '../models/training_history_entry.dart';
import 'weekly_history_aggregation.dart';

/// Bornes calendaires locales d'un mois civil, début inclus et fin exclue.
class LocalMonth {
  const LocalMonth({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  factory LocalMonth.containing(DateTime date) {
    final local = date.toLocal();
    return LocalMonth(
      start: DateTime(local.year, local.month),
      end: DateTime(local.year, local.month + 1),
    );
  }

  LocalMonth previous() =>
      LocalMonth.containing(DateTime(start.year, start.month - 1, start.day));

  LocalMonth next() =>
      LocalMonth.containing(DateTime(start.year, start.month + 1, start.day));

  bool contains(DateTime date) {
    final local = date.toLocal();
    return !local.isBefore(start) && local.isBefore(end);
  }

  bool hasSameStart(LocalMonth other) => start == other.start;
}

/// Agrégat d'une semaine civile, limité aux jours du mois affiché.
class MonthlyHistoryWeekBucket {
  const MonthlyHistoryWeekBucket({
    required this.week,
    required this.aggregationStart,
    required this.aggregationEnd,
    required this.completedCount,
    required this.incompleteCount,
    required this.totalDuration,
  });

  final LocalWeek week;
  final DateTime aggregationStart;
  final DateTime aggregationEnd;
  final int completedCount;
  final int incompleteCount;
  final Duration totalDuration;

  int get totalCount => completedCount + incompleteCount;

  bool isEntirelyFuture(DateTime today) {
    final local = today.toLocal();
    final localDay = DateTime(local.year, local.month, local.day);
    return aggregationStart.isAfter(localDay);
  }
}

/// État mensuel directement exploitable par la présentation.
class MonthlyHistorySummary {
  const MonthlyHistorySummary({
    required this.month,
    required this.entries,
    required this.weeks,
    required this.completedCount,
    required this.incompleteCount,
    required this.totalDuration,
  });

  final LocalMonth month;
  final List<TrainingHistoryEntry> entries;
  final List<MonthlyHistoryWeekBucket> weeks;
  final int completedCount;
  final int incompleteCount;
  final Duration totalDuration;

  int get totalCount => entries.length;
}

/// Regroupe un mois civil en semaines lundi-dimanche. Les semaines aux bords
/// conservent leurs bornes civiles complètes mais n'agrègent que les jours du
/// mois.
MonthlyHistorySummary aggregateHistoryMonth(
  Iterable<TrainingHistoryEntry> allEntries,
  LocalMonth month,
) {
  final entries =
      allEntries.where((entry) => month.contains(entry.date)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  final buckets = <MonthlyHistoryWeekBucket>[];

  var week = LocalWeek.containing(month.start);
  while (week.start.isBefore(month.end)) {
    final aggregationStart = week.start.isBefore(month.start)
        ? month.start
        : week.start;
    final aggregationEnd = week.end.isAfter(month.end) ? month.end : week.end;
    final bucketEntries = entries.where((entry) {
      final local = entry.date.toLocal();
      return !local.isBefore(aggregationStart) &&
          local.isBefore(aggregationEnd);
    });
    var completedCount = 0;
    var incompleteCount = 0;
    var durationInMicroseconds = 0;

    for (final entry in bucketEntries) {
      if (entry.status == TrainingSessionStatus.completed) {
        completedCount++;
      } else {
        incompleteCount++;
      }
      if (!entry.totalDuration.isNegative) {
        durationInMicroseconds += entry.totalDuration.inMicroseconds;
      }
    }

    buckets.add(
      MonthlyHistoryWeekBucket(
        week: week,
        aggregationStart: aggregationStart,
        aggregationEnd: aggregationEnd,
        completedCount: completedCount,
        incompleteCount: incompleteCount,
        totalDuration: Duration(microseconds: durationInMicroseconds),
      ),
    );
    week = week.next();
  }

  final completedCount = entries
      .where((entry) => entry.status == TrainingSessionStatus.completed)
      .length;
  final totalDurationInMicroseconds = buckets.fold<int>(
    0,
    (total, bucket) => total + bucket.totalDuration.inMicroseconds,
  );

  return MonthlyHistorySummary(
    month: month,
    entries: List.unmodifiable(entries),
    weeks: List.unmodifiable(buckets),
    completedCount: completedCount,
    incompleteCount: entries.length - completedCount,
    totalDuration: Duration(microseconds: totalDurationInMicroseconds),
  );
}

const _frenchMonths = [
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

String formatLocalMonthLabel(LocalMonth month) =>
    '${_frenchMonths[month.start.month - 1]} ${month.start.year}';

String formatMonthlyBucketLabel(MonthlyHistoryWeekBucket bucket) {
  final last = DateTime(
    bucket.aggregationEnd.year,
    bucket.aggregationEnd.month,
    bucket.aggregationEnd.day - 1,
  );
  return bucket.aggregationStart.day == last.day
      ? '${last.day}'
      : '${bucket.aggregationStart.day}–${last.day}';
}

String formatMonthlyBucketPeriod(MonthlyHistoryWeekBucket bucket) =>
    '${formatMonthlyBucketLabel(bucket)} '
    '${_frenchMonths[bucket.aggregationStart.month - 1]}';
