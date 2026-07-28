import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/screens/group_editor.dart';
import 'package:rep_timer/screens/training_editor.dart';

void main() {
  testWidgets('la séance affiche les groupes en lecture seule et repliables', (
    tester,
  ) async {
    final training = Training.fromJson({
      'id': 'training',
      'name': 'Full Body',
      'createdAt': '2026-07-27T10:00:00.000',
      'groups': [
        {
          'id': 'legs',
          'name': 'Jambes',
          'rounds': 2,
          'items': [
            {
              'type': 'exercise',
              'name': 'Squats',
              'repetitions': 12,
              'durationSeconds': null,
              'isFreeDuration': false,
              'comment': null,
              'iconName': null,
            },
            {
              'type': 'rest',
              'name': 'Pause',
              'repetitions': null,
              'durationSeconds': 30,
              'isFreeDuration': false,
              'comment': null,
              'iconName': null,
            },
            {
              'type': 'exercise',
              'name': 'Fentes',
              'repetitions': null,
              'durationSeconds': 90,
              'isFreeDuration': false,
              'comment': null,
              'iconName': null,
            },
          ],
        },
        {
          'id': 'core',
          'name': 'Tronc',
          'rounds': 1,
          'items': [
            {
              'type': 'exercise',
              'name': 'Gainage',
              'repetitions': null,
              'durationSeconds': null,
              'isFreeDuration': true,
              'comment': null,
              'iconName': null,
            },
          ],
        },
      ],
    });

    await _pumpTrainingEditor(tester, training);

    expect(find.text('Groupe libre'), findsNWidgets(2));
    expect(find.text('Répétitions : 2'), findsOneWidget);
    expect(find.text('12 répétitions'), findsOneWidget);
    expect(find.text('00:30'), findsOneWidget);
    expect(find.text('01:30'), findsOneWidget);
    expect(find.text('Durée libre'), findsOneWidget);
    expect(find.byTooltip('Modifier'), findsNothing);

    await tester.tap(find.text('Jambes'));
    await tester.pumpAndSettle();

    expect(find.text('Squats'), findsNothing);
    expect(find.text('Gainage'), findsOneWidget);
    expect(find.text('Groupe libre'), findsNWidgets(2));
    expect(find.byTooltip('Éditer le groupe'), findsNWidgets(2));
    expect(find.byTooltip('Supprimer le groupe'), findsNWidgets(2));
  });

  testWidgets('ajouter, éditer et annuler un groupe reste transactionnel', (
    tester,
  ) async {
    final training = _training([
      ExerciseGroup(
        id: 'group',
        name: 'Initial',
        rounds: 2,
        items: [
          TrainingItem(
            type: ItemType.exercise,
            name: 'Élément',
            repetitions: 8,
          ),
        ],
      ),
    ]);

    await _pumpTrainingEditor(tester, training);
    await tester.tap(find.text('Initial'));
    await tester.pumpAndSettle();
    expect(find.text('Élément'), findsNothing);

    await tester.tap(find.byTooltip('Éditer le groupe'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Modifié');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Modifié'), findsOneWidget);
    expect(find.text('Élément'), findsNothing);
    expect(training.groups.single.name, 'Initial');

    await tester.tap(find.byTooltip('Éditer le groupe'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Annulé');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // GroupEditor est désormais aligné sur showUnsavedChangesDialog
    // (3 choix), le même dialogue que TrainingEditor : titre et libellé
    // du bouton "abandonner" diffèrent de l'ancien showConfirmDialog.
    expect(find.text('Modifications non enregistrées'), findsOneWidget);
    await tester.tap(find.text('Abandonner les modifications'));
    await tester.pumpAndSettle();

    expect(find.text('Modifié'), findsOneWidget);
    expect(find.text('Annulé'), findsNothing);

    await tester.tap(find.text('Ajouter un groupe'));
    await tester.pumpAndSettle();
    expect(find.text('Ajout de groupe'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Nouveau');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Nouveau'), findsOneWidget);
  });

  testWidgets('la suppression d’un groupe nécessite une confirmation', (
    tester,
  ) async {
    await _pumpTrainingEditor(
      tester,
      _training([ExerciseGroup(id: 'group', name: 'À supprimer', items: [])]),
    );

    await tester.tap(find.byTooltip('Supprimer le groupe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.text('À supprimer'), findsOneWidget);

    await tester.tap(find.byTooltip('Supprimer le groupe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('À supprimer'), findsNothing);
  });

  testWidgets('l’éditeur gère répétitions, déplacements et suppression', (
    tester,
  ) async {
    ExerciseGroup? savedGroup;
    final original = ExerciseGroup(
      id: 'group',
      name: 'Circuit',
      items: [
        TrainingItem(type: ItemType.exercise, name: 'Premier', repetitions: 10),
        TrainingItem(type: ItemType.exercise, name: 'Second', repetitions: 20),
      ],
    );

    await _pumpGroupLauncher(
      tester,
      original,
      onResult: (group) => savedGroup = group,
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    final minus = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.remove_circle_outline),
    );
    expect(minus.onPressed, isNull);

    await tester.tap(find.byTooltip('Plus de répétitions'));
    await tester.tap(find.byTooltip('Descendre').first);
    await tester.pump();

    await tester.tap(find.byTooltip('Supprimer').first);
    await tester.pumpAndSettle();
    expect(find.text("Supprimer l'exercice ?"), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);

    await tester.tap(find.byTooltip('Supprimer').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(savedGroup!.rounds, 2);
    expect(savedGroup!.items.single.name, 'Premier');
    expect(original.rounds, 1);
    expect(original.items.map((item) => item.name), ['Premier', 'Second']);
  });

  testWidgets('les éléments peuvent être réordonnés par glisser-déposer', (
    tester,
  ) async {
    ExerciseGroup? savedGroup;

    await _pumpGroupLauncher(
      tester,
      ExerciseGroup(
        id: 'group',
        name: 'Circuit',
        items: [
          TrainingItem(
            type: ItemType.exercise,
            name: 'Premier',
            repetitions: 10,
          ),
          TrainingItem(
            type: ItemType.exercise,
            name: 'Second',
            repetitions: 20,
          ),
          TrainingItem(
            type: ItemType.exercise,
            name: 'Troisième',
            repetitions: 30,
          ),
        ],
      ),
      onResult: (group) => savedGroup = group,
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byIcon(Icons.drag_handle).first,
      const Offset(0, 220),
      touchSlopY: 0,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(savedGroup!.items.map((item) => item.name), [
      'Second',
      'Premier',
      'Troisième',
    ]);
  });

  testWidgets('un nom vide est refusé et le retour peut être annulé', (
    tester,
  ) async {
    ExerciseGroup? savedGroup;

    await _pumpGroupLauncher(
      tester,
      ExerciseGroup(id: 'group', name: 'Circuit', items: []),
      onResult: (group) => savedGroup = group,
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(find.text('Merci de donner un nom au groupe'), findsOneWidget);
    expect(find.text('Édition du groupe'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Modifié');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.text('Édition du groupe'), findsOneWidget);
    expect(savedGroup, isNull);
  });
}

Training _training(List<ExerciseGroup> groups) {
  return Training(
    id: 'training',
    name: 'Séance',
    groups: groups,
    createdAt: DateTime(2026, 7, 27),
  );
}

Future<void> _pumpTrainingEditor(WidgetTester tester, Training training) async {
  await tester.pumpWidget(
    MaterialApp(home: TrainingEditor(training: training)),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpGroupLauncher(
  WidgetTester tester,
  ExerciseGroup group, {
  required ValueChanged<ExerciseGroup?> onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              final result = await Navigator.push<ExerciseGroup>(
                context,
                MaterialPageRoute(builder: (_) => GroupEditor(group: group)),
              );
              onResult(result);
            },
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}