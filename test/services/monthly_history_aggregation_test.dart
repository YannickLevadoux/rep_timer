import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/services/monthly_history_aggregation.dart';

void main() {
  group('LocalMonth', () {
    test('délimite un mois civil et traverse décembre/janvier', () {
      final december = LocalMonth.containing(DateTime(2026, 12, 18));

      expect(december.start, DateTime(2026, 12));
      expect(december.end, DateTime(2027));
      expect(december.contains(DateTime(2026, 12, 31, 23, 59)), isTrue);
      expect(december.contains(DateTime(2027)), isFalse);
      expect(december.next().start, DateTime(2027));
      expect(december.previous().start, DateTime(2026, 11));
    });
  });

  group('aggregateHistoryMonth', () {
    test('produit quatre semaines pour février 2021, 28 jours', () {
      final summary = aggregateHistoryMonth(
        const [],
        LocalMonth.containing(DateTime(2021, 2, 10)),
      );

      expect(summary.weeks, hasLength(4));
      expect(summary.weeks.first.aggregationStart, DateTime(2021, 2));
      expect(summary.weeks.last.aggregationEnd, DateTime(2021, 3));
    });

    test('gère février d’une année bissextile', () {
      final summary = aggregateHistoryMonth(
        const [],
        LocalMonth.containing(DateTime(2024, 2, 29)),
      );

      expect(summary.weeks, hasLength(5));
      expect(summary.weeks.first.aggregationStart, DateTime(2024, 2));
      expect(summary.weeks.last.aggregationEnd, DateTime(2024, 3));
      expect(
        summary.weeks.last.aggregationEnd
            .difference(summary.weeks.last.aggregationStart)
            .inDays,
        4,
      );
    });

    test('gère les mois de 30 et 31 jours', () {
      final april = aggregateHistoryMonth(
        const [],
        LocalMonth.containing(DateTime(2026, 4, 15)),
      );
      final july = aggregateHistoryMonth(
        const [],
        LocalMonth.containing(DateTime(2026, 7, 15)),
      );

      expect(april.month.end, DateTime(2026, 5));
      expect(july.month.end, DateTime(2026, 8));
      expect(april.weeks, hasLength(5));
      expect(july.weeks, hasLength(5));
    });

    test('gère un mois commençant un lundi', () {
      final summary = aggregateHistoryMonth(
        const [],
        LocalMonth.containing(DateTime(2026, 6, 15)),
      );

      expect(summary.weeks.first.week.start, DateTime(2026, 6));
      expect(summary.weeks.first.aggregationStart, DateTime(2026, 6));
      expect(formatMonthlyBucketLabel(summary.weeks.first), '1–7');
    });

    test('gère un mois commençant un dimanche et ses semaines partielles', () {
      final summary = aggregateHistoryMonth(
        const [],
        LocalMonth.containing(DateTime(2026, 2, 15)),
      );

      expect(summary.weeks.first.week.start, DateTime(2026, 1, 26));
      expect(summary.weeks.first.aggregationStart, DateTime(2026, 2));
      expect(summary.weeks.first.aggregationEnd, DateTime(2026, 2, 2));
      expect(formatMonthlyBucketLabel(summary.weeks.first), '1');
      expect(summary.weeks.last.aggregationEnd, DateTime(2026, 3));
    });

    test('produit six semaines et limite les deux semaines aux bords', () {
      final summary = aggregateHistoryMonth(
        const [],
        LocalMonth.containing(DateTime(2026, 8, 5)),
      );

      expect(summary.weeks, hasLength(6));
      expect(summary.weeks.first.week.start, DateTime(2026, 7, 27));
      expect(summary.weeks.first.aggregationStart, DateTime(2026, 8));
      expect(summary.weeks.first.aggregationEnd, DateTime(2026, 8, 3));
      expect(formatMonthlyBucketLabel(summary.weeks.first), '1–2');
      expect(summary.weeks.last.week.end, DateTime(2026, 9, 7));
      expect(summary.weeks.last.aggregationStart, DateTime(2026, 8, 31));
      expect(summary.weeks.last.aggregationEnd, DateTime(2026, 9));
      expect(formatMonthlyBucketLabel(summary.weeks.last), '31');
    });

    test('exclut les mois voisins et trie les entrées décroissantes', () {
      final summary = aggregateHistoryMonth([
        _entry('juillet', DateTime(2026, 7, 31, 23, 59)),
        _entry('début août', DateTime(2026, 8, 1)),
        _entry('fin août', DateTime(2026, 8, 31, 23, 59)),
        _entry('septembre', DateTime(2026, 9)),
      ], LocalMonth.containing(DateTime(2026, 8, 5)));

      expect(summary.entries.map((entry) => entry.id), [
        'fin août',
        'début août',
      ]);
      expect(summary.weeks.first.totalCount, 1);
      expect(summary.weeks.last.totalCount, 1);
    });

    test('attribue toute une séance traversant minuit au mois de fin', () {
      final summary = aggregateHistoryMonth([
        _entry(
          'traverse le mois',
          DateTime(2026, 8, 1, 0, 3),
          duration: const Duration(minutes: 40),
        ),
      ], LocalMonth.containing(DateTime(2026, 8, 5)));

      expect(summary.totalCount, 1);
      expect(summary.totalDuration, const Duration(minutes: 40));
      expect(summary.weeks.first.totalDuration, const Duration(minutes: 40));
    });

    test('compte les statuts par semaine et cumule toutes les durées', () {
      final summary = aggregateHistoryMonth([
        _entry(
          'terminée',
          DateTime(2026, 8, 4),
          duration: const Duration(minutes: 20),
        ),
        _entry(
          'incomplète',
          DateTime(2026, 8, 5),
          status: TrainingSessionStatus.incomplete,
          duration: const Duration(minutes: 12, seconds: 35),
        ),
        _entry(
          'négative',
          DateTime(2026, 8, 6),
          duration: const Duration(seconds: -30),
        ),
      ], LocalMonth.containing(DateTime(2026, 8, 5)));

      final bucket = summary.weeks[1];
      expect(bucket.completedCount, 2);
      expect(bucket.incompleteCount, 1);
      expect(bucket.totalCount, 3);
      expect(bucket.totalDuration, const Duration(minutes: 32, seconds: 35));
      expect(summary.completedCount, 2);
      expect(summary.incompleteCount, 1);
      expect(summary.totalDuration, const Duration(minutes: 32, seconds: 35));
    });

    test('conserve les buckets et les totaux nuls pour un mois vide', () {
      final summary = aggregateHistoryMonth([
        _entry('hors mois', DateTime(2026, 7, 15)),
      ], LocalMonth.containing(DateTime(2026, 8, 5)));

      expect(summary.entries, isEmpty);
      expect(summary.weeks, hasLength(6));
      expect(summary.weeks.map((week) => week.totalCount), everyElement(0));
      expect(summary.totalDuration, Duration.zero);
    });
  });
}

TrainingHistoryEntry _entry(
  String id,
  DateTime date, {
  TrainingSessionStatus status = TrainingSessionStatus.completed,
  Duration duration = const Duration(minutes: 1),
}) {
  return TrainingHistoryEntry(
    id: id,
    trainingId: id,
    trainingName: id,
    date: date,
    totalDuration: duration,
    status: status,
  );
}
