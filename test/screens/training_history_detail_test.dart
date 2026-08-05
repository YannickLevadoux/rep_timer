import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/history_step_entry.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/screens/training_history_detail.dart';
import 'package:rep_timer/widgets/training_history_header.dart';

void main() {
  testWidgets('affiche les quatre statistiques dans le bon ordre et la date', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final entry = _detailedEntry();

    await _pumpDetail(tester, entry);

    _expectBadge(
      tester,
      key: const Key('history-completed-badge'),
      label: 'Réalisés',
      value: '2 / 3',
      tooltip: 'Exercices réalisés : 2 sur 3',
    );
    _expectBadge(
      tester,
      key: const Key('history-total-duration-badge'),
      label: 'Total',
      value: '02:03:04',
      tooltip: 'Durée totale : 02:03:04',
    );
    _expectBadge(
      tester,
      key: const Key('history-work-duration-badge'),
      label: 'Travail',
      value: '01:01:13',
      tooltip: 'Durée de travail : 01:01:13',
    );
    _expectBadge(
      tester,
      key: const Key('history-rest-duration-badge'),
      label: 'Pause',
      value: '03:11',
      tooltip: 'Durée de pause : 03:11',
    );

    final badges = [
      find.byKey(const Key('history-completed-badge')),
      find.byKey(const Key('history-total-duration-badge')),
      find.byKey(const Key('history-work-duration-badge')),
      find.byKey(const Key('history-rest-duration-badge')),
    ];
    final top = tester.getTopLeft(badges.first).dy;
    final width = tester.getSize(badges.first).width;
    var previousLeft = double.negativeInfinity;
    for (final badge in badges) {
      expect(tester.getTopLeft(badge).dy, top);
      expect(tester.getSize(badge).width, width);
      expect(tester.getTopLeft(badge).dx, greaterThan(previousLeft));
      previousLeft = tester.getTopLeft(badge).dx;
    }

    final header = find.byKey(const Key('history-statistics-header'));
    expect(
      tester.widget<ColoredBox>(header).color,
      TrainingHistoryHeader.backgroundColor,
    );
    final date = find.byKey(const Key('history-entry-date'));
    expect(find.text('04/08/2026 à 13:45'), findsOneWidget);
    expect(
      tester.getTopLeft(date).dy,
      greaterThan(tester.getBottomLeft(badges.first).dy),
    );
    expect(tester.getTopRight(date).dx, tester.getTopRight(header).dx - 12);

    semantics.dispose();
  });

  testWidgets('les groupes sont repliés puis contrôlés indépendamment', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpDetail(tester, _detailedEntry());

    expect(find.text('Groupe A'), findsOneWidget);
    expect(find.text('01:04:11'), findsOneWidget);
    expect(find.text('Groupe B'), findsOneWidget);
    expect(find.text('00:13'), findsOneWidget);
    expect(find.text('Exercice A1 × 12'), findsNothing);
    expect(find.text('Exercice B1'), findsNothing);
    expect(
      find.bySemanticsLabel('Groupe A, durée 01:04:11, groupe replié'),
      findsOneWidget,
    );

    await tester.tap(find.text('Groupe A'));
    await tester.pump();

    expect(find.text('Exercice A1 × 12'), findsOneWidget);
    expect(find.text('Commentaire A'), findsOneWidget);
    expect(find.text('Seconde ligne masquée'), findsNothing);
    expect(find.text('Exercice B1'), findsNothing);
    expect(
      find.bySemanticsLabel('Groupe A, durée 01:04:11, groupe développé'),
      findsOneWidget,
    );

    await tester.tap(find.text('Groupe B'));
    await tester.pump();
    expect(find.text('Exercice A1 × 12'), findsOneWidget);
    expect(find.text('Exercice B1'), findsOneWidget);

    await tester.tap(find.text('Groupe A'));
    await tester.pump();
    expect(find.text('Exercice A1 × 12'), findsNothing);
    expect(find.text('Exercice B1'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('une ancienne entrée conserve la date et le message de détail', (
    tester,
  ) async {
    final entry = TrainingHistoryEntry(
      id: 'ancienne',
      trainingId: 'training',
      trainingName: 'Ancienne séance',
      date: DateTime(2024, 2, 3, 9, 7),
      totalDuration: const Duration(minutes: 42),
    );

    await _pumpDetail(tester, entry, allowDelete: false);

    expect(find.text('03/02/2024 à 09:07'), findsOneWidget);
    expect(find.text('0 / 0'), findsOneWidget);
    expect(
      find.text('Détails non disponibles pour cette séance.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.delete))
          .onPressed,
      isNull,
    );
  });

  testWidgets('reste sans débordement sur petite largeur et texte agrandi', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(240, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final steps = List.generate(
      123,
      (index) => HistoryStepEntry(
        groupId: 'long-group',
        groupName: 'Un nom de groupe particulièrement long',
        itemType: ItemType.exercise,
        itemName: 'Exercice $index',
        comment: null,
        actualDuration: const Duration(hours: 1, minutes: 2, seconds: 3),
        completed: index < 12,
      ),
    );
    final entry = TrainingHistoryEntry(
      id: 'responsive',
      trainingId: 'training',
      trainingName: 'Un nom de séance particulièrement long',
      date: DateTime(2026, 8, 4, 13, 45),
      totalDuration: const Duration(hours: 123, minutes: 45, seconds: 6),
      steps: steps,
    );

    await _pumpDetail(tester, entry, textScale: 2);

    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byKey(const Key('history-completed-badge')),
        matching: find.text('12 / 123'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('history-total-duration-badge')),
        matching: find.text('123:45:06'),
      ),
      findsOneWidget,
    );
    expect(find.text('04/08/2026 à 13:45'), findsOneWidget);
  });

  testWidgets('le fond et le contraste de l’en-tête restent fixes par thème', (
    tester,
  ) async {
    for (final theme in [ThemeData.light(), ThemeData.dark()]) {
      await _pumpDetail(tester, _detailedEntry(), theme: theme);
      expect(
        tester
            .widget<ColoredBox>(
              find.byKey(const Key('history-statistics-header')),
            )
            .color,
        TrainingHistoryHeader.backgroundColor,
      );
      expect(
        tester
            .widget<Icon>(
              find.descendant(
                of: find.byKey(const Key('history-completed-badge')),
                matching: find.byIcon(Icons.check_circle_outline),
              ),
            )
            .color,
        Colors.white,
      );
    }
  });
}

void _expectBadge(
  WidgetTester tester, {
  required Key key,
  required String label,
  required String value,
  required String tooltip,
}) {
  final badge = find.byKey(key);
  expect(badge, findsOneWidget);
  expect(
    find.descendant(of: badge, matching: find.text(label)),
    findsOneWidget,
  );
  expect(
    find.descendant(of: badge, matching: find.text(value)),
    findsOneWidget,
  );
  expect(find.byTooltip(tooltip), findsOneWidget);
  expect(find.bySemanticsLabel(tooltip), findsOneWidget);
}

Future<void> _pumpDetail(
  WidgetTester tester,
  TrainingHistoryEntry entry, {
  bool allowDelete = true,
  ThemeData? theme,
  double textScale = 1,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: TrainingHistoryDetailScreen(entry: entry, allowDelete: allowDelete),
    ),
  );
}

TrainingHistoryEntry _detailedEntry() {
  return TrainingHistoryEntry(
    id: 'detail',
    trainingId: 'training',
    trainingName: 'Séance détaillée',
    date: DateTime(2026, 8, 4, 13, 45),
    totalDuration: const Duration(hours: 2, minutes: 3, seconds: 4),
    steps: [
      _step(
        groupId: 'a',
        groupName: 'Groupe A',
        name: 'Exercice A1',
        duration: const Duration(hours: 1, minutes: 1, seconds: 2),
        completed: true,
        repetitions: 12,
        comment: 'Commentaire A\nSeconde ligne masquée',
      ),
      _step(
        groupId: 'a',
        groupName: 'Groupe A',
        name: 'Pause A',
        type: ItemType.rest,
        duration: const Duration(minutes: 3, seconds: 4),
        completed: true,
      ),
      _step(
        groupId: 'a',
        groupName: 'Groupe A',
        name: 'Exercice A2',
        duration: const Duration(seconds: 5),
        completed: false,
      ),
      _step(
        groupId: 'b',
        groupName: 'Groupe B',
        name: 'Exercice B1',
        duration: const Duration(seconds: 6),
        completed: true,
      ),
      _step(
        groupId: 'b',
        groupName: 'Groupe B',
        name: 'Pause B',
        type: ItemType.rest,
        duration: const Duration(seconds: 7),
        completed: true,
      ),
    ],
  );
}

HistoryStepEntry _step({
  required String groupId,
  required String groupName,
  required String name,
  required Duration duration,
  required bool completed,
  ItemType type = ItemType.exercise,
  String? comment,
  int? repetitions,
}) {
  return HistoryStepEntry(
    groupId: groupId,
    groupName: groupName,
    itemType: type,
    itemName: name,
    repetitions: repetitions,
    comment: comment,
    actualDuration: duration,
    completed: completed,
  );
}
