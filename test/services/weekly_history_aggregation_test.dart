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
      expect(summary.days, hasLength(7));
      expect(
        summary.days.map((day) => day.duration),
        everyElement(Duration.zero),
      );
      expect(summary.days.map((day) => day.sessionCount), everyElement(0));
      expect(summary.days.map((day) => day.completedCount), everyElement(0));
      expect(summary.days.map((day) => day.incompleteCount), everyElement(0));
      expect(summary.totalDuration, Duration.zero);
    });

    test('cumule plusieurs séances et leurs statuts le même jour', () {
      final week = LocalWeek.containing(DateTime(2026, 8, 5));

      final summary = aggregateHistoryWeek([
        _entry(
          'terminée',
          DateTime(2026, 8, 4, 8),
          TrainingSessionStatus.completed,
          duration: const Duration(minutes: 20),
        ),
        _entry(
          'incomplète',
          DateTime(2026, 8, 4, 18),
          TrainingSessionStatus.incomplete,
          duration: const Duration(minutes: 12, seconds: 35),
        ),
        _entry(
          'terminée 2',
          DateTime(2026, 8, 4, 20),
          TrainingSessionStatus.completed,
          duration: const Duration(minutes: 5),
        ),
      ], week);

      expect(
        summary.days[1].duration,
        const Duration(minutes: 37, seconds: 35),
      );
      expect(summary.days[1].sessionCount, 3);
      expect(summary.days[1].completedCount, 2);
      expect(summary.days[1].incompleteCount, 1);
      expect(summary.totalDuration, const Duration(minutes: 37, seconds: 35));
    });

    test('répartit les séances entre les jours et inclut Quick Tabata', () {
      final week = LocalWeek.containing(DateTime(2026, 8, 5));

      final summary = aggregateHistoryWeek([
        _entry(
          'lundi',
          DateTime(2026, 8, 3, 10),
          TrainingSessionStatus.completed,
          duration: const Duration(minutes: 10),
        ),
        _entry(
          'tabata',
          DateTime(2026, 8, 7, 10),
          TrainingSessionStatus.completed,
          duration: const Duration(minutes: 4),
          name: 'Quick Tabata',
        ),
      ], week);

      expect(summary.days[0].duration, const Duration(minutes: 10));
      expect(summary.days[4].duration, const Duration(minutes: 4));
      expect(summary.days[0].sessionCount, 1);
      expect(summary.days[4].sessionCount, 1);
      expect(summary.days[0].completedCount, 1);
      expect(summary.days[4].completedCount, 1);
      expect(summary.totalDuration, const Duration(minutes: 14));
    });

    test(
      'conserve une séance nulle et neutralise une ancienne durée négative',
      () {
        final week = LocalWeek.containing(DateTime(2026, 8, 5));
        final negative = _entry(
          'négative',
          DateTime(2026, 8, 3),
          TrainingSessionStatus.completed,
          duration: const Duration(seconds: -30),
        );

        final summary = aggregateHistoryWeek([
          negative,
          _entry(
            'nulle',
            DateTime(2026, 8, 3, 1),
            TrainingSessionStatus.incomplete,
            duration: Duration.zero,
          ),
        ], week);

        expect(summary.days[0].duration, Duration.zero);
        expect(summary.days[0].sessionCount, 2);
        expect(summary.days[0].completedCount, 1);
        expect(summary.days[0].incompleteCount, 1);
        expect(summary.totalDuration, Duration.zero);
        expect(negative.totalDuration, const Duration(seconds: -30));
      },
    );

    test('inclut la borne du lundi et exclut celle du lundi suivant', () {
      final week = LocalWeek.containing(DateTime(2026, 8, 5));

      final summary = aggregateHistoryWeek([
        _entry(
          'début',
          DateTime(2026, 8, 3),
          TrainingSessionStatus.completed,
          duration: const Duration(minutes: 5),
        ),
        _entry(
          'fin',
          DateTime(2026, 8, 10),
          TrainingSessionStatus.completed,
          duration: const Duration(minutes: 50),
        ),
      ], week);

      expect(summary.totalCount, 1);
      expect(summary.days[0].duration, const Duration(minutes: 5));
      expect(summary.days[0].completedCount, 1);
      expect(summary.days[6].sessionCount, 0);
      expect(summary.totalDuration, const Duration(minutes: 5));
    });

    test('attribue toute une séance traversant minuit à son jour de fin', () {
      final week = LocalWeek.containing(DateTime(2026, 8, 5));

      final summary = aggregateHistoryWeek([
        _entry(
          'traverse minuit',
          DateTime(2026, 8, 4, 0, 5),
          TrainingSessionStatus.completed,
          duration: const Duration(minutes: 40),
        ),
      ], week);

      expect(summary.days[0].duration, Duration.zero);
      expect(summary.days[1].duration, const Duration(minutes: 40));
      expect(summary.days[1].sessionCount, 1);
    });
  });
}

TrainingHistoryEntry _entry(
  String id,
  DateTime date,
  TrainingSessionStatus status, {
  String? name,
  Duration duration = const Duration(minutes: 1),
}) {
  return TrainingHistoryEntry(
    id: id,
    trainingId: id,
    trainingName: name ?? id,
    date: date,
    totalDuration: duration,
    status: status,
  );
}
