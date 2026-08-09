import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/controllers/training_history_controller.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/screens/training_history.dart';
import 'package:rep_timer/services/json_prefs_storage.dart';
import 'package:rep_timer/services/training_history_storage.dart';
import 'package:rep_timer/widgets/training_history_content.dart';

void main() {
  final now = DateTime(2026, 8, 5, 12);

  testWidgets('s’ouvre sur la semaine courante et désactive la suivante', (
    tester,
  ) async {
    final storage = _FakeHistoryStorage(const StorageNoData());

    await _pumpHistory(tester, storage, now: now);

    expect(find.text('3–9 août 2026'), findsOneWidget);
    expect(find.text('0 séance'), findsOneWidget);
    expect(find.text('Aucune séance sur cette période'), findsOneWidget);
    expect(find.text('Séances de la semaine — 0'), findsOneWidget);
    expect(find.text('Tout Visualiser'), findsNothing);
    expect(
      tester
          .widget<DropdownButton<HistoryMetric>>(
            find.byKey(const Key('history-metric-selector')),
          )
          .value,
      HistoryMetric.sessionCount,
    );
    expect(find.byKey(const Key('weekly-history-duration-card')), findsNothing);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('next-week-button')))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'passe au temps passé et affiche sept jours sur une échelle commune',
    (tester) async {
      final storage = _FakeHistoryStorage(
        StorageReadSuccess([
          _entry(
            'mardi matin',
            DateTime(2026, 8, 4, 8),
            duration: const Duration(hours: 1),
          ),
          _entry(
            'mardi soir',
            DateTime(2026, 8, 4, 20),
            status: TrainingSessionStatus.incomplete,
            duration: const Duration(minutes: 12, seconds: 35),
          ),
          _entry(
            'mercredi',
            DateTime(2026, 8, 5),
            duration: const Duration(minutes: 30),
          ),
        ]),
      );

      await _pumpHistory(tester, storage, now: now);
      await _selectTimeSpent(tester);

      expect(
        find.byKey(const Key('weekly-history-duration-card')),
        findsOneWidget,
      );
      expect(find.text('Temps total — 01:42:35'), findsOneWidget);
      for (final day in ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']) {
        expect(find.text(day), findsOneWidget);
      }
      for (var index = 0; index < 7; index++) {
        expect(find.byKey(Key('weekly-duration-bar-$index')), findsOneWidget);
      }

      final tuesdayHeight = tester
          .getSize(find.byKey(const Key('weekly-duration-value-1')))
          .height;
      final wednesdayHeight = tester
          .getSize(find.byKey(const Key('weekly-duration-value-2')))
          .height;
      expect(tuesdayHeight, greaterThan(wednesdayHeight));
      expect(find.byIcon(Icons.today), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsNWidgets(4));
      expect(find.text('Séances de la semaine — 3'), findsOneWidget);
    },
  );

  testWidgets('conserve la semaine choisie lors du changement de métrique', (
    tester,
  ) async {
    final storage = _FakeHistoryStorage(
      StorageReadSuccess([
        _entry('précédente', DateTime(2026, 7, 28)),
        _entry('courante', DateTime(2026, 8, 4)),
      ]),
    );

    await _pumpHistory(tester, storage, now: now);
    await tester.tap(find.byKey(const Key('previous-week-button')));
    await tester.pump();
    await _selectTimeSpent(tester);

    expect(find.text('27 juillet–2 août 2026'), findsOneWidget);
    expect(find.text('précédente'), findsOneWidget);
    expect(find.text('courante'), findsNothing);
    expect(find.text('Temps total — 00:01:00'), findsOneWidget);
    expect(storage.loadCalls, 1);
  });

  testWidgets('un appui détaille la date, la durée et le nombre de séances', (
    tester,
  ) async {
    final storage = _FakeHistoryStorage(
      StorageReadSuccess([
        _entry(
          'une',
          DateTime(2026, 8, 4, 8),
          duration: const Duration(hours: 1),
        ),
        _entry(
          'deux',
          DateTime(2026, 8, 4, 18),
          duration: const Duration(minutes: 12, seconds: 35),
        ),
      ]),
    );

    await _pumpHistory(tester, storage, now: now);
    await _selectTimeSpent(tester);
    await tester.tap(find.byKey(const Key('weekly-duration-bar-1')));
    await tester.pump();

    expect(find.text('Mardi 4 août — 01:12:35 · 2 séances'), findsOneWidget);
  });

  testWidgets('navigue en mémoire vers la semaine précédente et revient', (
    tester,
  ) async {
    final storage = _FakeHistoryStorage(
      StorageReadSuccess([
        _entry('courante', DateTime(2026, 8, 4)),
        _entry('précédente', DateTime(2026, 7, 30)),
      ]),
    );

    await _pumpHistory(tester, storage, now: now);
    expect(find.text('courante'), findsOneWidget);
    expect(find.text('précédente'), findsNothing);

    await tester.tap(find.byKey(const Key('previous-week-button')));
    await tester.pump();

    expect(find.text('27 juillet–2 août 2026'), findsOneWidget);
    expect(find.text('courante'), findsNothing);
    expect(find.text('précédente'), findsOneWidget);
    expect(find.text('Aujourd’hui'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('next-week-button')))
          .onPressed,
      isNotNull,
    );
    expect(storage.loadCalls, 1);

    await tester.tap(find.byKey(const Key('today-button')));
    await tester.pump();

    expect(find.text('3–9 août 2026'), findsOneWidget);
    expect(find.text('courante'), findsOneWidget);
    expect(find.text('Aujourd’hui'), findsNothing);
    expect(storage.loadCalls, 1);
  });

  testWidgets('affiche le bilan par statut et toutes les séances triées', (
    tester,
  ) async {
    final entries = [
      for (var index = 0; index < 6; index++)
        _entry(
          'séance $index',
          DateTime(2026, 8, 3 + index),
          status: index < 4
              ? TrainingSessionStatus.completed
              : TrainingSessionStatus.incomplete,
        ),
      _entry('hors période', DateTime(2026, 7, 20)),
    ];
    final storage = _FakeHistoryStorage(StorageReadSuccess(entries));

    await _pumpHistory(tester, storage, now: now);

    expect(
      find.text('6 séances — 4 terminées · 2 incomplètes'),
      findsOneWidget,
    );
    expect(find.text('Séances de la semaine — 6'), findsOneWidget);
    expect(find.text('hors période'), findsNothing);
    expect(find.text('séance 5'), findsOneWidget);
    expect(find.text('Tout Visualiser'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('séance 0'),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('séance 0'), findsOneWidget);
  });

  testWidgets(
    'affiche une barre empilée visible avec les couleurs des statuts',
    (tester) async {
      final storage = _FakeHistoryStorage(
        StorageReadSuccess([
          _entry('terminée 1', DateTime(2026, 8, 5)),
          _entry('terminée 2', DateTime(2026, 8, 4)),
          _entry(
            'incomplète',
            DateTime(2026, 8, 3),
            status: TrainingSessionStatus.incomplete,
          ),
        ]),
      );

      await _pumpHistory(tester, storage, now: now);

      final completedBar = find.byKey(
        const Key('weekly-history-completed-bar'),
      );
      final incompleteBar = find.byKey(
        const Key('weekly-history-incomplete-bar'),
      );
      expect(tester.getSize(completedBar).height, 20);
      expect(tester.getSize(incompleteBar).height, 20);
      expect(
        tester.getSize(completedBar).width,
        closeTo(tester.getSize(incompleteBar).width * 2, 0.01),
      );

      final completedColor = tester.widget<ColoredBox>(completedBar).color;
      final incompleteColor = tester.widget<ColoredBox>(incompleteBar).color;
      expect(completedColor, Colors.green.shade700);
      expect(
        incompleteColor,
        tester
            .widget<Icon>(
              find.byKey(const Key('history-entry-status-incomplète')),
            )
            .color,
      );
    },
  );

  testWidgets('recalcule le bilan et la liste après suppression', (
    tester,
  ) async {
    final storage = _FakeHistoryStorage(
      StorageReadSuccess([
        _entry('à supprimer', DateTime(2026, 8, 5)),
        _entry(
          'à garder',
          DateTime(2026, 8, 4),
          status: TrainingSessionStatus.incomplete,
        ),
      ]),
    );

    await _pumpHistory(tester, storage, now: now);
    expect(find.text('2 séances — 1 terminée · 1 incomplète'), findsOneWidget);

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.delete_outline).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();

    expect(storage.deletedIds, ['à supprimer']);
    expect(find.text('à supprimer'), findsNothing);
    expect(find.text('1 séance — 0 terminée · 1 incomplète'), findsOneWidget);
    expect(find.text('Séances de la semaine — 1'), findsOneWidget);
  });

  testWidgets('recalcule les durées après suppression', (tester) async {
    final storage = _FakeHistoryStorage(
      StorageReadSuccess([
        _entry(
          'à supprimer',
          DateTime(2026, 8, 5),
          duration: const Duration(minutes: 20),
        ),
        _entry(
          'à garder',
          DateTime(2026, 8, 4),
          duration: const Duration(minutes: 10),
        ),
      ]),
    );

    await _pumpHistory(tester, storage, now: now);
    await _selectTimeSpent(tester);
    expect(find.text('Temps total — 00:30:00'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.widgetWithIcon(IconButton, Icons.delete_outline).first,
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.delete_outline).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('Temps total — 00:10:00'), findsOneWidget);
    expect(find.text('Séances de la semaine — 1'), findsOneWidget);
  });

  testWidgets(
    'la récupération partielle avertit et conserve les statistiques',
    (tester) async {
      final storage = _FakeHistoryStorage(
        StorageReadPartial(
          [_entry('valide', DateTime(2026, 8, 5))],
          rejectedIndexes: const [1],
        ),
      );

      await _pumpHistory(tester, storage, now: now);

      await _selectTimeSpent(tester);

      expect(find.text('Temps total — 00:01:00'), findsOneWidget);
      expect(
        find.textContaining('statistiques peuvent être incomplètes'),
        findsOneWidget,
      );
      expect(find.text('valide'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.delete_outline),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('le graphique fournit un résumé sémantique textuel', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final storage = _FakeHistoryStorage(
      StorageReadSuccess([
        _entry('terminée', DateTime(2026, 8, 5)),
        _entry(
          'incomplète',
          DateTime(2026, 8, 4),
          status: TrainingSessionStatus.incomplete,
        ),
      ]),
    );

    await _pumpHistory(tester, storage, now: now);

    expect(
      find.bySemanticsLabel(
        'Bilan hebdomadaire : 2 séances — 1 terminée · 1 incomplète',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('chaque barre de durée expose son détail sémantique', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final storage = _FakeHistoryStorage(
      StorageReadSuccess([
        _entry(
          'mardi',
          DateTime(2026, 8, 4),
          duration: const Duration(minutes: 12, seconds: 35),
        ),
      ]),
    );

    await _pumpHistory(tester, storage, now: now);
    await _selectTimeSpent(tester);

    expect(
      find.bySemanticsLabel('Mardi 4 août — 00:12:35 · 1 séance'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Jeudi 6 août — 00:00:00 · 0 séance. Jour à venir'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('utilise la couleur principale en thème clair et sombre', (
    tester,
  ) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final storage = _FakeHistoryStorage(
        StorageReadSuccess([
          _entry(
            'activité',
            DateTime(2026, 8, 4),
            duration: const Duration(minutes: 10),
          ),
        ]),
      );
      final scheme = ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: brightness,
      );

      await _pumpHistory(tester, storage, now: now, colorScheme: scheme);
      await _selectTimeSpent(tester);

      final value = tester.widget<Container>(
        find.byKey(const Key('weekly-duration-value-1')),
      );
      expect((value.decoration! as BoxDecoration).color, scheme.primary);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets(
    'reste défilable sans débordement sur petit écran et grand texte',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(240, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final storage = _FakeHistoryStorage(
        StorageReadSuccess([
          _entry(
            'Une séance au nom particulièrement long',
            DateTime(2026, 8, 5),
          ),
        ]),
      );

      await _pumpHistory(tester, storage, now: now, textScale: 2);

      await _selectTimeSpent(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(CustomScrollView), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sélectionne le mois contenant l’ancre de la semaine', (
    tester,
  ) async {
    final storage = _FakeHistoryStorage(
      StorageReadSuccess([
        _entry('juillet', DateTime(2026, 7, 29)),
        _entry('août', DateTime(2026, 8, 4)),
      ]),
    );

    await _pumpHistory(tester, storage, now: now);
    expect(
      tester
          .widget<SegmentedButton<HistoryPeriod>>(
            find.byKey(const Key('history-period-selector')),
          )
          .selected,
      {HistoryPeriod.week},
    );
    await tester.tap(find.byKey(const Key('previous-week-button')));
    await tester.pump();
    await _selectMonth(tester);

    expect(find.text('juillet 2026'), findsOneWidget);
    expect(find.text('Séances du mois — 1'), findsOneWidget);
    expect(find.text('juillet'), findsOneWidget);
    expect(find.text('août'), findsNothing);
  });

  testWidgets('affiche six barres et filtre la liste sur le mois civil', (
    tester,
  ) async {
    final storage = _FakeHistoryStorage(
      StorageReadSuccess([
        _entry('fin juillet', DateTime(2026, 7, 31)),
        _entry('début août', DateTime(2026, 8, 1)),
        _entry('fin août', DateTime(2026, 8, 31)),
        _entry('début septembre', DateTime(2026, 9, 1)),
      ]),
    );

    await _pumpHistory(tester, storage, now: now);
    await _selectMonth(tester);

    expect(find.text('août 2026'), findsOneWidget);
    expect(find.byKey(const Key('monthly-history-card')), findsOneWidget);
    for (var index = 0; index < 6; index++) {
      expect(find.byKey(Key('monthly-week-bar-$index')), findsOneWidget);
    }
    expect(find.text('2 séances — 2 terminées · 0 incomplète'), findsOneWidget);
    expect(find.text('Séances du mois — 2'), findsOneWidget);
    expect(find.text('début août'), findsOneWidget);
    expect(find.text('fin juillet'), findsNothing);
    expect(find.text('début septembre'), findsNothing);
  });

  testWidgets('navigue entre les mois sans permettre un mois futur', (
    tester,
  ) async {
    await _pumpHistory(
      tester,
      _FakeHistoryStorage(const StorageNoData()),
      now: now,
    );
    await _selectMonth(tester);

    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('next-month-button')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('previous-month-button')));
    await tester.pump();
    expect(find.text('juillet 2026'), findsOneWidget);
    expect(find.byKey(const Key('month-today-button')), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('next-month-button')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('month-today-button')));
    await tester.pump();
    expect(find.text('août 2026'), findsOneWidget);
    expect(find.byKey(const Key('month-today-button')), findsNothing);
  });

  testWidgets('conserve la métrique et cumule les durées de tous les statuts', (
    tester,
  ) async {
    final storage = _FakeHistoryStorage(
      StorageReadSuccess([
        _entry(
          'terminée',
          DateTime(2026, 8, 4),
          duration: const Duration(hours: 1),
        ),
        _entry(
          'incomplète',
          DateTime(2026, 8, 10),
          status: TrainingSessionStatus.incomplete,
          duration: const Duration(minutes: 12, seconds: 35),
        ),
      ]),
    );

    await _pumpHistory(tester, storage, now: now);
    await _selectTimeSpent(tester);
    await _selectMonth(tester);

    expect(find.text('Temps total — 01:12:35'), findsOneWidget);
    expect(find.byKey(const Key('monthly-duration-value-1')), findsOneWidget);
    expect(find.byKey(const Key('monthly-duration-value-2')), findsOneWidget);
    expect(
      tester
          .widget<DropdownButton<HistoryMetric>>(
            find.byKey(const Key('history-metric-selector')),
          )
          .value,
      HistoryMetric.timeSpent,
    );
  });

  testWidgets('une barre partielle ouvre sa semaine civile complète', (
    tester,
  ) async {
    final storage = _FakeHistoryStorage(
      StorageReadSuccess([
        _entry('voisine de juillet', DateTime(2026, 7, 31)),
        _entry('dans août', DateTime(2026, 8, 1)),
        _entry('autre semaine', DateTime(2026, 8, 4)),
      ]),
    );

    await _pumpHistory(tester, storage, now: now);
    await _selectMonth(tester);
    await tester.tap(find.byKey(const Key('monthly-week-bar-0')));
    await tester.pump();

    expect(find.text('27 juillet–2 août 2026'), findsOneWidget);
    expect(find.text('Séances de la semaine — 2'), findsOneWidget);
    expect(find.text('voisine de juillet'), findsOneWidget);
    expect(find.text('dans août'), findsOneWidget);
    expect(find.text('autre semaine'), findsNothing);
    expect(
      tester
          .widget<SegmentedButton<HistoryPeriod>>(
            find.byKey(const Key('history-period-selector')),
          )
          .selected,
      {HistoryPeriod.week},
    );
  });

  testWidgets('recalcule le mois immédiatement après suppression', (
    tester,
  ) async {
    final storage = _FakeHistoryStorage(
      StorageReadSuccess([
        _entry('à supprimer du mois', DateTime(2026, 8, 5)),
        _entry(
          'à garder dans le mois',
          DateTime(2026, 8, 4),
          status: TrainingSessionStatus.incomplete,
        ),
      ]),
    );

    await _pumpHistory(tester, storage, now: now);
    await _selectMonth(tester);
    expect(find.text('2 séances — 1 terminée · 1 incomplète'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.widgetWithIcon(IconButton, Icons.delete_outline).first,
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.delete_outline).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('1 séance — 0 terminée · 1 incomplète'), findsOneWidget);
    expect(find.text('Séances du mois — 1'), findsOneWidget);
  });

  testWidgets('un mois vide conserve ses six barres', (tester) async {
    await _pumpHistory(
      tester,
      _FakeHistoryStorage(const StorageNoData()),
      now: now,
    );
    await _selectMonth(tester);

    expect(find.text('0 séance'), findsOneWidget);
    expect(find.text('Aucune séance sur cette période'), findsOneWidget);
    expect(find.text('Séances du mois — 0'), findsOneWidget);
    expect(find.byKey(const Key('monthly-week-bar-5')), findsOneWidget);
  });

  testWidgets('affiche quatre barres pour février 2021', (tester) async {
    await _pumpHistory(
      tester,
      _FakeHistoryStorage(const StorageNoData()),
      now: DateTime(2021, 2, 10),
    );
    await _selectMonth(tester);

    for (var index = 0; index < 4; index++) {
      expect(find.byKey(Key('monthly-week-bar-$index')), findsOneWidget);
    }
    expect(find.byKey(const Key('monthly-week-bar-4')), findsNothing);
  });

  testWidgets(
    'les données partielles alimentent le mois et bloquent la suppression',
    (tester) async {
      final storage = _FakeHistoryStorage(
        StorageReadPartial(
          [_entry('valide du mois', DateTime(2026, 8, 4))],
          rejectedIndexes: const [1],
        ),
      );

      await _pumpHistory(tester, storage, now: now);
      await _selectMonth(tester);

      expect(find.text('1 séance — 1 terminée · 0 incomplète'), findsOneWidget);
      expect(
        find.textContaining('statistiques peuvent être incomplètes'),
        findsOneWidget,
      );
      expect(find.text('valide du mois'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.delete_outline),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'les durées mensuelles utilisent la couleur principale des thèmes',
    (tester) async {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        final scheme = ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: brightness,
        );
        await _pumpHistory(
          tester,
          _FakeHistoryStorage(
            StorageReadSuccess([_entry('activité', DateTime(2026, 8, 4))]),
          ),
          now: now,
          colorScheme: scheme,
        );
        await _selectTimeSpent(tester);
        await _selectMonth(tester);

        final value = tester.widget<DecoratedBox>(
          find.byKey(const Key('monthly-duration-value-1')),
        );
        expect((value.decoration as BoxDecoration).color, scheme.primary);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets('le mois et chaque barre exposent un résumé sémantique', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final storage = _FakeHistoryStorage(
      StorageReadSuccess([
        _entry('une', DateTime(2026, 8, 1)),
        _entry(
          'deux',
          DateTime(2026, 8, 2),
          status: TrainingSessionStatus.incomplete,
        ),
      ]),
    );

    await _pumpHistory(tester, storage, now: now);
    await _selectMonth(tester);

    expect(
      find.bySemanticsLabel(
        'Bilan mensuel de août 2026 : '
        '2 séances — 1 terminée · 1 incomplète',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('1–2 août — 2 séances · 1 terminée · 1 incomplète'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('la vue mensuelle reste utilisable sur petit écran en sombre', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(240, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    );

    await _pumpHistory(
      tester,
      _FakeHistoryStorage(
        StorageReadSuccess([_entry('activité', DateTime(2026, 8, 4))]),
      ),
      now: now,
      textScale: 2,
      colorScheme: scheme,
    );
    await _selectMonth(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('monthly-history-card')),
      150,
      scrollable: find.byType(Scrollable),
    );
    expect(find.byKey(const Key('monthly-week-bar-5')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHistory(
  WidgetTester tester,
  TrainingHistoryStore storage, {
  required DateTime now,
  double textScale = 1,
  ColorScheme? colorScheme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: colorScheme == null ? null : ThemeData(colorScheme: colorScheme),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: TrainingHistoryScreen(
        controller: TrainingHistoryController(storage: storage, now: () => now),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

TrainingHistoryEntry _entry(
  String name,
  DateTime date, {
  TrainingSessionStatus status = TrainingSessionStatus.completed,
  Duration duration = const Duration(minutes: 1),
}) {
  return TrainingHistoryEntry(
    id: name,
    trainingId: name,
    trainingName: name,
    date: date,
    totalDuration: duration,
    status: status,
  );
}

Future<void> _selectTimeSpent(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('history-metric-selector')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Temps passé').last);
  await tester.pumpAndSettle();
}

Future<void> _selectMonth(WidgetTester tester) async {
  await tester.tap(find.text('Mois'));
  await tester.pumpAndSettle();
}

class _FakeHistoryStorage implements TrainingHistoryStore {
  _FakeHistoryStorage(this.result);

  final StorageReadResult<List<TrainingHistoryEntry>> result;
  int loadCalls = 0;
  final List<String> deletedIds = [];

  @override
  Future<StorageReadResult<List<TrainingHistoryEntry>>> loadHistory() async {
    loadCalls++;
    return result;
  }

  @override
  Future<void> deleteEntry(String id) async {
    deletedIds.add(id);
  }
}
