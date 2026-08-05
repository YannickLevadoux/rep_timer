import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/services/weekly_history_aggregation.dart';

void main() {
  group('LocalWeek', () {
    test('commence le lundi à minuit et finit au lundi exclu', () {
      final week = LocalWeek.containing(DateTime(2026, 8, 5, 18, 30));

      expect(week.start, DateTime(2026, 8, 3));
      expect(week.end, DateTime(2026, 8, 10));
      expect(week.contains(DateTime(2026, 8, 3)), isTrue);
      expect(week.contains(DateTime(2026, 8, 9, 23, 59, 59, 999)), isTrue);
      expect(week.contains(DateTime(2026, 8, 10)), isFalse);
    });

    test('gère une semaine à cheval sur deux mois', () {
      final week = LocalWeek.containing(DateTime(2026, 7, 1));

      expect(week.start, DateTime(2026, 6, 29));
      expect(week.end, DateTime(2026, 7, 6));
    });

    test('gère une semaine à cheval sur deux années', () {
      final week = LocalWeek.containing(DateTime(2027, 1, 1));

      expect(week.start, DateTime(2026, 12, 28));
      expect(week.end, DateTime(2027, 1, 4));
    });

    test(
      'construit les bornes par dates calendaires au changement d’heure',
      () {
        final week = LocalWeek.containing(DateTime(2026, 3, 29, 12));

        expect(week.start, DateTime(2026, 3, 23));
        expect(week.end, DateTime(2026, 3, 30));
        expect(week.start.hour, 0);
        expect(week.end.hour, 0);
      },
    );
  });

  group('aggregateHistoryWeek', () {
    test('attribue au jour de fin, compte les statuts et trie décroissant', () {
      final week = LocalWeek.containing(DateTime(2026, 8, 5));
      final entries = [
        _entry(
          'avant-minuit',
          DateTime(2026, 8, 2, 23, 59),
          TrainingSessionStatus.completed,
        ),
        _entry(
          'traverse-minuit',
          DateTime(2026, 8, 3, 0, 2),
          TrainingSessionStatus.incomplete,
        ),
        _entry(
          'quick-tabata',
          DateTime(2026, 8, 7, 9),
          TrainingSessionStatus.completed,
          name: 'Quick Tabata',
        ),
        _entry(
          'plus-recente',
          DateTime(2026, 8, 9, 20),
          TrainingSessionStatus.completed,
        ),
        _entry(
          'borne-exclue',
          DateTime(2026, 8, 10),
          TrainingSessionStatus.incomplete,
        ),
      ];

      final summary = aggregateHistoryWeek(entries, week);

      expect(summary.totalCount, 3);
      expect(summary.completedCount, 2);
      expect(summary.incompleteCount, 1);
      expect(summary.entries.map((entry) => entry.id), [
        'plus-recente',
        'quick-tabata',
        'traverse-minuit',
      ]);
    });

    test('produit un bilan vide', () {
      final summary = aggregateHistoryWeek([
        _entry(
          'hors-semaine',
          DateTime(2026, 7, 1),
          TrainingSessionStatus.completed,
        ),
      ], LocalWeek.containing(DateTime(2026, 8, 5)));

      expect(summary.entries, isEmpty);
      expect(summary.completedCount, 0);
      expect(summary.incompleteCount, 0);
    });
  });
}

TrainingHistoryEntry _entry(
  String id,
  DateTime date,
  TrainingSessionStatus status, {
  String? name,
}) {
  return TrainingHistoryEntry(
    id: id,
    trainingId: id,
    trainingName: name ?? id,
    date: date,
    totalDuration: const Duration(minutes: 1),
    status: status,
  );
}
