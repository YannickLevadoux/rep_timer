import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/screens/group_editor.dart';
import 'package:rep_timer/widgets/rounds_editor.dart';

void main() {
  testWidgets('RoundsEditor conserve ses tooltips et ses cibles tactiles', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RoundsEditor(rounds: 2, onChanged: (_) {})),
      ),
    );

    final minus = find.byTooltip('Moins de répétitions');
    final plus = find.byTooltip('Plus de répétitions');

    expect(minus, findsOneWidget);
    expect(plus, findsOneWidget);
    expect(tester.getSize(minus).width, greaterThanOrEqualTo(40));
    expect(tester.getSize(minus).height, greaterThanOrEqualTo(40));
    expect(tester.getSize(plus).width, greaterThanOrEqualTo(40));
    expect(tester.getSize(plus).height, greaterThanOrEqualTo(40));
  });

  testWidgets('GroupEditor continue de piloter ses rounds avec RoundsEditor', (
    tester,
  ) async {
    final group = ExerciseGroup(
      id: 'group',
      name: 'Groupe',
      rounds: 2,
      items: [],
    );
    await tester.pumpWidget(MaterialApp(home: GroupEditor(group: group)));

    expect(tester.widget<RoundsEditor>(find.byType(RoundsEditor)).rounds, 2);

    await tester.tap(find.byTooltip('Plus de répétitions'));
    await tester.pump();

    expect(tester.widget<RoundsEditor>(find.byType(RoundsEditor)).rounds, 3);
  });

  testWidgets('les boutons sont désactivés aux deux bornes métier', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RoundsEditor(rounds: 1, onChanged: (_) {})),
      ),
    );
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.remove_circle_outline),
          )
          .onPressed,
      isNull,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RoundsEditor(rounds: 999, onChanged: (_) {})),
      ),
    );
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.add_circle_outline),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('signale les valeurs hors bornes avec un libellé personnalisé', (
    tester,
  ) async {
    final changes = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoundsEditor(
            rounds: 0,
            minimum: 1,
            maximum: 3,
            label: 'Tours',
            onChanged: changes.add,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('rounds-error')), findsOneWidget);
    expect(find.text('La valeur minimale est 1.'), findsOneWidget);
    expect(find.byTooltip('Diminuer Tours'), findsOneWidget);
    expect(find.byTooltip('Augmenter Tours'), findsOneWidget);

    await tester.tap(find.byTooltip('Augmenter Tours'));
    expect(changes, <int>[1]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoundsEditor(
            rounds: 4,
            minimum: 1,
            maximum: 3,
            label: 'Tours',
            onChanged: changes.add,
          ),
        ),
      ),
    );
    expect(find.text('La valeur maximale est 3.'), findsOneWidget);
    await tester.tap(find.byTooltip('Diminuer Tours'));
    expect(changes, <int>[1, 3]);
  });
}
