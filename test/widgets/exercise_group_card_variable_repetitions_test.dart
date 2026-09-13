import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/widgets/exercise_group_card.dart';

void main() {
  testWidgets(
    'affiche la suite variable sur chaque exercice et garde la pause',
    (tester) async {
      final group = ExerciseGroup(
        id: 'variable',
        name: 'Pyramide',
        type: GroupType.variableRepetitions,
        repetitionSequence: [10, 12, 15],
        items: [
          TrainingItem(type: ItemType.exercise, name: 'Squats', repetitions: 1),
          TrainingItem(type: ItemType.exercise, name: 'Fentes', repetitions: 6),
          TrainingItem(
            type: ItemType.rest,
            name: 'Pause',
            duration: const Duration(seconds: 30),
          ),
        ],
      );

      await _pumpCard(tester, group);

      expect(find.text('3 tours'), findsOneWidget);
      expect(find.text('3 tours · 10 → 12 → 15'), findsNothing);
      expect(find.text('3 t. · 10 → 12 → 15'), findsNWidgets(2));
      expect(find.text('1 répétitions'), findsNothing);
      expect(find.text('6 répétitions'), findsNothing);
      expect(find.text('00:30'), findsOneWidget);
    },
  );

  testWidgets('abrège aussi une suite variable à un seul tour', (tester) async {
    await _pumpCard(tester, _variableGroup(repetitionSequence: [8]));

    expect(find.text('1 tour'), findsOneWidget);
    expect(find.text('1 t. · 8'), findsOneWidget);
  });

  testWidgets('affiche le libellé de repli pour une suite vide', (
    tester,
  ) async {
    await _pumpCard(tester, _variableGroup(repetitionSequence: const []));

    expect(find.text('0 tours'), findsOneWidget);
    expect(find.text('Suite à définir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('conserve les valeurs des groupes libres et chronométrés', (
    tester,
  ) async {
    final freeGroup = ExerciseGroup(
      id: 'free',
      name: 'Libre',
      items: [
        TrainingItem(type: ItemType.exercise, name: 'Pompes', repetitions: 12),
      ],
    );

    await _pumpCard(tester, freeGroup);
    expect(find.text('12 répétitions'), findsOneWidget);

    await _pumpCard(tester, ExerciseGroup.tabata(id: 'tabata'));
    expect(find.text('00:20'), findsOneWidget);
    expect(find.text('00:10'), findsOneWidget);
  });

  testWidgets('tronque les textes sans overflow à 360 px et texte agrandi', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final group = ExerciseGroup(
      id: 'variable',
      name: 'Pyramide avec un nom particulièrement long',
      type: GroupType.variableRepetitions,
      repetitionSequence: [10, 12, 15, 20, 25, 30],
      items: [
        TrainingItem(
          type: ItemType.exercise,
          name: 'Squats bulgares avec un titre particulièrement long',
          repetitions: 1,
        ),
      ],
    );

    await _pumpCard(tester, group, textScale: 2);

    expect(tester.takeException(), isNull);
    final title = tester.widget<Text>(find.text(group.items.single.name));
    final summary = tester.widget<Text>(
      find.text('6 t. · 10 → 12 → 15 → 20 → 25 → 30'),
    );
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(summary.maxLines, 1);
    expect(summary.overflow, TextOverflow.ellipsis);
    expect(
      tester.getSize(find.text(group.items.single.name)).width,
      greaterThan(tester.getSize(find.byWidget(summary)).width * 1.9),
    );
  });
}

ExerciseGroup _variableGroup({required List<int> repetitionSequence}) {
  return ExerciseGroup(
    id: 'variable',
    name: 'Pyramide',
    type: GroupType.variableRepetitions,
    repetitionSequence: repetitionSequence,
    items: [
      TrainingItem(type: ItemType.exercise, name: 'Squats', repetitions: 1),
    ],
  );
}

Future<void> _pumpCard(
  WidgetTester tester,
  ExerciseGroup group, {
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
      home: Scaffold(
        body: ExerciseGroupCard(
          group: group,
          onDelete: () {},
          onEdit: () {},
          onExpanded: (_) {},
          index: 0,
          expanded: true,
          hasFollowingGroup: false,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
