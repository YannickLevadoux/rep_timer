import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/controllers/training_history_controller.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/screens/training_history.dart';
import 'package:rep_timer/services/json_prefs_storage.dart';
import 'package:rep_timer/services/training_history_storage.dart';

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
          .widget<IconButton>(find.byKey(const Key('next-week-button')))
          .onPressed,
      isNull,
    );
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

      expect(find.text('1 séance — 1 terminée · 0 incomplète'), findsOneWidget);
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

      expect(tester.takeException(), isNull);
      expect(find.byType(CustomScrollView), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpHistory(
  WidgetTester tester,
  TrainingHistoryStore storage, {
  required DateTime now,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
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
}) {
  return TrainingHistoryEntry(
    id: name,
    trainingId: name,
    trainingName: name,
    date: date,
    totalDuration: const Duration(minutes: 1),
    status: status,
  );
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
