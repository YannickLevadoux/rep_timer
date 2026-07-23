import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/screens/exercise_group_editor.dart';
import 'package:rep_timer/screens/training_editor.dart';

void main() {
  test("un ancien groupe sans type devient un groupe libre", () {
    final group = ExerciseGroup.fromJson({
      'id': 'group-1',
      'name': 'Circuit',
      'rounds': 2,
      'items': <dynamic>[],
    });

    expect(group.type, ExerciseGroupType.free);
    expect(group.toJson()['type'], ExerciseGroupType.free.name);
  });

  testWidgets("l'éditeur applique sa copie uniquement après enregistrement", (
    tester,
  ) async {
    final original = ExerciseGroup(
      id: 'group-1',
      name: 'Circuit',
      items: [
        TrainingItem(type: ItemType.exercise, name: 'Pompes', repetitions: 10),
      ],
    );
    ExerciseGroup? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                saved = await Navigator.push<ExerciseGroup>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ExerciseGroupEditorScreen(group: original),
                  ),
                );
              },
              child: const Text("Ouvrir"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Ouvrir"));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), "Circuit modifié");
    expect(original.name, "Circuit");

    await tester.tap(find.byTooltip("Supprimer"));
    await tester.pumpAndSettle();
    expect(find.text("Supprimer l'exercice ?"), findsOneWidget);

    await tester.tap(find.text("Annuler"));
    await tester.pumpAndSettle();
    expect(find.text("Pompes"), findsOneWidget);

    await tester.tap(find.text("Enregistrer"));
    await tester.pumpAndSettle();

    expect(original.name, "Circuit");
    expect(saved?.name, "Circuit modifié");
    expect(saved?.items.single.name, "Pompes");
  });

  testWidgets("la synthèse confirme la suppression d'un groupe", (
    tester,
  ) async {
    final training = Training(
      id: 'training-1',
      name: 'Séance',
      createdAt: DateTime(2026),
      groups: [
        ExerciseGroup(
          id: 'group-1',
          name: 'Circuit',
          rounds: 2,
          items: [
            TrainingItem(
              type: ItemType.exercise,
              name: 'Pompes',
              repetitions: 10,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: TrainingEditor(training: training)),
    );

    expect(find.text("Groupe libre"), findsOneWidget);
    expect(find.text("Répétitions : 2"), findsOneWidget);
    expect(find.text("10 répétitions"), findsOneWidget);

    await tester.tap(find.byTooltip("Supprimer"));
    await tester.pumpAndSettle();

    expect(find.text("Supprimer le groupe ?"), findsOneWidget);
    expect(find.text("Circuit"), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, "Supprimer"));
    await tester.pumpAndSettle();

    expect(find.text("Aucun groupe"), findsOneWidget);
  });
}
