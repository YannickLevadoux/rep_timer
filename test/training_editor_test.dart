import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/screens/group_editor.dart';
import 'package:rep_timer/screens/training_editor.dart';
import 'package:rep_timer/widgets/editable_item_tile.dart';
import 'package:rep_timer/widgets/type_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('une nouvelle séance édite son nom depuis le titre', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TrainingEditor()));
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(find.text('Nouvelle séance'));
    expect(title.style?.fontStyle, FontStyle.italic);
    expect(find.byType(TextField), findsNothing);
    expect(find.byTooltip('Modifier le nom de la séance'), findsOneWidget);

    await tester.tap(find.byTooltip('Modifier le nom de la séance'));
    await tester.pumpAndSettle();

    expect(find.text('Nom de la séance'), findsNWidgets(2));
    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).textCapitalization,
      TextCapitalization.sentences,
    );
    expect(tester.testTextInput.hasAnyClients, isTrue);

    await tester.enterText(find.byType(TextField), '  Full Body  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Full Body'), findsOneWidget);
  });

  testWidgets('annuler l’édition conserve le nom de la séance', (tester) async {
    await _pumpTrainingEditor(tester, _training(const []));

    await tester.tap(find.byTooltip('Modifier le nom de la séance'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Nom annulé');
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.text('Séance'), findsOneWidget);
    expect(find.text('Nom annulé'), findsNothing);
  });

  testWidgets('l’erreur de nom vide disparaît dès la saisie', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TrainingEditor()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Cardio');
    await tester.pump();

    expect(find.text('Ce champ est obligatoire.'), findsNothing);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Valider'));
    await tester.pump();
    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Cardio');
    await tester.pump();
    expect(find.text('Ce champ est obligatoire.'), findsNothing);
  });

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
    expect(find.text('Squats'), findsNothing);
    expect(find.text('Gainage'), findsNothing);
    expect(find.byTooltip('Modifier'), findsNothing);
    expect(find.byTooltip('Éditer le groupe'), findsNWidgets(2));
    expect(find.byTooltip('Supprimer le groupe'), findsNWidgets(2));

    await tester.tap(find.text('Jambes'));
    await tester.pumpAndSettle();

    expect(find.text('Squats'), findsOneWidget);
    expect(find.text('12 répétitions'), findsOneWidget);
    expect(find.text('00:30'), findsOneWidget);
    expect(find.text('01:30'), findsOneWidget);
    expect(find.text('Gainage'), findsNothing);
    expect(find.text('Groupe libre'), findsNWidgets(2));

    await tester.tap(find.text('Jambes'));
    await tester.pumpAndSettle();

    expect(find.text('Squats'), findsNothing);
    expect(find.text('Gainage'), findsNothing);
  });

  testWidgets(
    'l’expansion est locale, ne salit pas la séance et repart repliée',
    (tester) async {
      final training = _training([
        ExerciseGroup(
          id: 'group',
          name: 'Circuit',
          items: [
            TrainingItem(
              type: ItemType.exercise,
              name: 'Burpees',
              repetitions: 8,
            ),
          ],
        ),
      ]);

      await _pumpTrainingLauncher(tester, training);
      await tester.tap(find.text('Ouvrir la séance'));
      await tester.pumpAndSettle();

      expect(find.text('Burpees'), findsNothing);
      await tester.tap(find.text('Circuit'));
      await tester.pumpAndSettle();
      expect(find.text('Burpees'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Modifications non enregistrées'), findsNothing);
      expect(find.text('Ouvrir la séance'), findsOneWidget);
      expect(training.groups.single.expanded, isTrue);

      await tester.tap(find.text('Ouvrir la séance'));
      await tester.pumpAndSettle();
      expect(find.text('Burpees'), findsNothing);
    },
  );

  testWidgets('l’expansion n’est pas incluse dans la sauvegarde', (
    tester,
  ) async {
    final group = ExerciseGroup(
      id: 'group',
      name: 'Circuit',
      expanded: false,
      items: [
        TrainingItem(type: ItemType.exercise, name: 'Burpees', repetitions: 8),
      ],
    );
    final training = _training([group]);

    await _pumpTrainingLauncher(tester, training);
    await tester.tap(find.text('Ouvrir la séance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Circuit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final raw = (await SharedPreferences.getInstance()).getString('trainings');
    final saved = jsonDecode(raw!) as List<dynamic>;
    final savedTraining = saved.single as Map<String, dynamic>;
    final savedGroups = savedTraining['groups'] as List<dynamic>;
    final savedGroup = savedGroups.single as Map<String, dynamic>;

    expect(savedGroup, isNot(contains('expanded')));
    expect(group.expanded, isFalse);
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
    expect(find.text('Élément'), findsNothing);

    await tester.tap(find.byTooltip('Éditer le groupe'));
    await tester.pumpAndSettle();
    await _editGroupName(tester, 'Modifié');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Modifié'), findsOneWidget);
    expect(find.text('Élément'), findsNothing);
    expect(training.groups.single.name, 'Initial');

    await tester.tap(find.byTooltip('Éditer le groupe'));
    await tester.pumpAndSettle();
    await _editGroupName(tester, 'Annulé');
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

    await tester.tap(find.byType(TypeSelector));
    await tester.pumpAndSettle();
    await tester.tap(find.text(GroupType.free.shortLabel).last);
    await tester.pumpAndSettle();
    await _editGroupName(tester, 'Nouveau');
    await tester.tap(find.text('Ajouter à la séance'));
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

  testWidgets('l’éditeur gère répétitions et suppression', (tester) async {
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
    expect(savedGroup!.items.single.name, 'Second');
    expect(original.rounds, 1);
    expect(original.items.map((item) => item.name), ['Premier', 'Second']);
  });

  testWidgets(
    'un groupe variable édite sa suite sans écraser les répétitions dormantes',
    (tester) async {
      ExerciseGroup? savedGroup;
      final original = ExerciseGroup(
        id: 'variable',
        name: 'Pyramide',
        type: GroupType.variableRepetitions,
        rounds: 4,
        repetitionSequence: [10, 12, 15],
        items: [
          TrainingItem(type: ItemType.exercise, name: 'Squats', repetitions: 6),
        ],
      );

      await _pumpGroupLauncher(
        tester,
        original,
        onResult: (group) => savedGroup = group,
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Variables'), findsOneWidget);
      expect(find.text('3 tours · 10 → 12 → 15'), findsOneWidget);
      expect(find.text('Nombre défini par la suite du groupe'), findsOneWidget);
      expect(find.byTooltip('Plus de répétitions'), findsNothing);

      await tester.tap(find.byTooltip('Modifier'));
      await tester.pumpAndSettle();
      expect(
        find.text('Nombre défini par la suite du groupe'),
        findsNWidgets(2),
      );
      expect(
        find.widgetWithText(TextField, 'Nombre de répétitions'),
        findsNothing,
      );
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-repetition-sequence')));
      await tester.pumpAndSettle();
      final sequenceFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(sequenceFields.at(1), '13');
      await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
      await tester.pumpAndSettle();
      expect(find.text('3 tours · 10 → 13 → 15'), findsOneWidget);

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(savedGroup!.repetitionSequence, [10, 13, 15]);
      expect(savedGroup!.rounds, 4);
      expect(savedGroup!.items.single.repetitions, 6);
      expect(original.repetitionSequence, [10, 12, 15]);
      expect(original.items.single.repetitions, 6);
    },
  );

  testWidgets(
    'un élément unique garde ses actions et une poignée accessible de 48 px',
    (tester) async {
      await _pumpGroupLauncher(
        tester,
        ExerciseGroup(
          id: 'group',
          name: 'Circuit',
          items: [
            TrainingItem(
              type: ItemType.rest,
              name: 'Pause',
              duration: const Duration(seconds: 30),
            ),
          ],
        ),
        onResult: (_) {},
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.byType(EditableItemTile), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(EditableItemTile),
          matching: find.text('Pause'),
        ),
        findsOneWidget,
      );
      expect(find.byTooltip('Monter'), findsNothing);
      expect(find.byTooltip('Descendre'), findsNothing);
      expect(find.byTooltip('Modifier'), findsOneWidget);
      expect(find.byTooltip('Supprimer'), findsOneWidget);
      expect(find.byTooltip('Réordonner'), findsOneWidget);

      final dragHandle = find.byType(ReorderableDragStartListener);
      expect(dragHandle, findsOneWidget);
      expect(tester.getSize(dragHandle), const Size(48, 48));

      final handleIcon = tester.widget<Icon>(find.byIcon(Icons.drag_handle));
      expect(handleIcon.size, 28);
    },
  );

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
      'Troisième',
      'Premier',
    ]);
  });

  testWidgets('un nom vide est refusé et le retour peut être annulé', (
    tester,
  ) async {
    ExerciseGroup? savedGroup;

    await _pumpGroupLauncher(
      tester,
      ExerciseGroup(id: 'group', name: '', items: []),
      onResult: (group) => savedGroup = group,
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Merci de donner un nom au groupe'), findsOneWidget);
    expect(find.text('Nom du groupe'), findsNWidgets(2));
    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Modifié');
    await tester.pump();
    expect(find.text('Ce champ est obligatoire.'), findsNothing);
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.text('Modifié'), findsOneWidget);
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

Future<void> _pumpTrainingLauncher(
  WidgetTester tester,
  Training training,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () => Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => TrainingEditor(training: training),
              ),
            ),
            child: const Text('Ouvrir la séance'),
          ),
        ),
      ),
    ),
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

Future<void> _editGroupName(WidgetTester tester, String name) async {
  await tester.tap(find.byTooltip('Modifier le nom du groupe'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), name);
  await tester.tap(find.text('Valider'));
  await tester.pumpAndSettle();
}
