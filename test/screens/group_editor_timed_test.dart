import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_editor_mode.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/screens/group_editor.dart';
import 'package:rep_timer/widgets/duration_minutes_seconds_picker.dart';
import 'package:rep_timer/widgets/exercise_form_controller.dart';
import 'package:rep_timer/widgets/type_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('les trois contextes affichent leur action dédiée', (
    tester,
  ) async {
    for (final scenario in [
      (GroupEditorMode.add, 'Ajouter à la séance'),
      (GroupEditorMode.edit, 'Enregistrer'),
      (GroupEditorMode.quick, 'Commencer'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: GroupEditor(
            group: ExerciseGroup(id: 'g', name: 'Groupe', items: []),
            mode: scenario.$1,
          ),
        ),
      );
      expect(find.text(scenario.$2), findsOneWidget);
    }
  });

  testWidgets('Tabata personnalise seulement la dernière pause persistante', (
    tester,
  ) async {
    await _pumpEditor(
      tester,
      ExerciseGroup.tabata(id: 'tabata')..rounds = 2,
      hasFollowingGroup: true,
    );

    expect(find.text('Temps total estimé'), findsOneWidget);
    expect(find.text('01:00'), findsOneWidget);
    final customize = find.text('Personnaliser la dernière pause');
    await tester.ensureVisible(customize);
    await tester.tap(customize);
    await tester.pump();
    expect(find.text('Dernière pause'), findsOneWidget);
    expect(find.byTooltip('Supprimer'), findsOneWidget);
    expect(find.byIcon(Icons.drag_handle), findsNothing);
  });

  testWidgets('Tabata aligne exercice et pauses avec leur durée', (
    tester,
  ) async {
    await _pumpEditor(tester, ExerciseGroup.tabata(id: 'tabata'));

    final effortRow = find.byKey(const Key('tabata-effort-row'));
    final effortIcon = find.descendant(
      of: effortRow,
      matching: find.byIcon(Icons.fitness_center),
    );
    final effortName = find.descendant(
      of: effortRow,
      matching: find.text('Effort'),
    );
    final edit = find.descendant(
      of: effortRow,
      matching: find.byTooltip("Modifier l'effort"),
    );
    final effortPicker = find.descendant(
      of: effortRow,
      matching: find.byType(DurationMinutesSecondsPicker),
    );
    expect(effortIcon, findsOneWidget);
    expect(effortName, findsOneWidget);
    expect(edit, findsOneWidget);
    expect(effortPicker, findsOneWidget);
    final effortNameText = tester.widget<Text>(effortName);
    expect(effortNameText.maxLines, 1);
    expect(effortNameText.overflow, TextOverflow.ellipsis);
    expect(
      tester.getTopLeft(effortIcon).dx,
      lessThan(tester.getTopLeft(effortName).dx),
    );
    expect(
      tester.getTopRight(effortName).dx,
      lessThan(tester.getTopLeft(edit).dx),
    );
    expect(
      tester.getTopRight(edit).dx,
      lessThan(tester.getTopLeft(effortPicker).dx),
    );
    _expectSameVerticalCenter(tester, [
      effortIcon,
      effortName,
      edit,
      effortPicker,
    ]);
    expect(
      tester.getTopRight(effortPicker).dx,
      closeTo(tester.getTopRight(effortRow).dx, 0.1),
    );

    final restRow = find.byKey(const Key('tabata-rest-row'));
    final restName = find.descendant(of: restRow, matching: find.text('Pause'));
    final restPicker = find.descendant(
      of: restRow,
      matching: find.byType(DurationMinutesSecondsPicker),
    );
    _expectSameVerticalCenter(tester, [restName, restPicker]);
    expect(
      tester.getTopRight(restPicker).dx,
      closeTo(tester.getTopRight(restRow).dx, 0.1),
    );
    expect(find.byType(Divider), findsNWidgets(2));

    final addFinalRest = find.widgetWithText(
      OutlinedButton,
      'Personnaliser la dernière pause',
    );
    expect(
      tester.getSize(addFinalRest).width,
      closeTo(tester.getSize(effortRow).width, 0.1),
    );
    await tester.ensureVisible(addFinalRest);
    await tester.tap(addFinalRest);
    await tester.pump();

    final finalRestRow = find.byKey(const Key('tabata-final-rest-row'));
    final finalRestName = find.descendant(
      of: finalRestRow,
      matching: find.text('Dernière pause'),
    );
    final delete = find.descendant(
      of: finalRestRow,
      matching: find.byTooltip('Supprimer'),
    );
    final finalRestPicker = find.descendant(
      of: finalRestRow,
      matching: find.byType(DurationMinutesSecondsPicker),
    );
    expect(finalRestName, findsOneWidget);
    expect(delete, findsOneWidget);
    expect(finalRestPicker, findsOneWidget);
    expect(
      tester.getTopRight(finalRestName).dx,
      lessThan(tester.getTopLeft(delete).dx),
    );
    expect(
      tester.getTopRight(delete).dx,
      lessThan(tester.getTopLeft(finalRestPicker).dx),
    );
    _expectSameVerticalCenter(tester, [finalRestName, delete, finalRestPicker]);
    expect(
      tester.getTopRight(finalRestPicker).dx,
      closeTo(tester.getTopRight(finalRestRow).dx, 0.1),
    );
    expect(find.byType(Divider), findsNWidgets(2));
  });

  testWidgets('Tabata masque les actions génériques et explique l’estimation', (
    tester,
  ) async {
    await _pumpEditor(tester, ExerciseGroup.tabata(id: 'tabata'));

    expect(find.widgetWithText(OutlinedButton, 'Exercice'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Pause'), findsNothing);
    await tester.ensureVisible(
      find.byTooltip('Informations sur la durée estimée'),
    );
    await tester.tap(find.byTooltip('Informations sur la durée estimée'));
    await tester.pumpAndSettle();

    expect(find.text("À propos de l'estimation"), findsOneWidget);
    expect(
      find.textContaining("incluse uniquement lorsqu'un autre groupe suit"),
      findsOneWidget,
    );
    expect(find.textContaining('pauses manuelles'), findsOneWidget);
  });

  testWidgets('AMRAP ajoute une récupération et adapte l’estimation', (
    tester,
  ) async {
    await _pumpEditor(
      tester,
      ExerciseGroup.amrap(id: 'amrap'),
      hasFollowingGroup: true,
    );

    expect(find.text('02:00'), findsOneWidget);
    await tester.tap(find.text("Ajouter une récupération après l'AMRAP"));
    await tester.pump();
    expect(find.text('03:00'), findsOneWidget);
    final recoveryRow = find.byKey(const Key('amrap-recovery-row'));
    final recoveryName = find.descendant(
      of: recoveryRow,
      matching: find.text('Récupération'),
    );
    final delete = find.descendant(
      of: recoveryRow,
      matching: find.byTooltip('Supprimer'),
    );
    final recoveryPicker = find.descendant(
      of: recoveryRow,
      matching: find.byType(DurationMinutesSecondsPicker),
    );
    expect(recoveryName, findsOneWidget);
    expect(delete, findsOneWidget);
    expect(recoveryPicker, findsOneWidget);
    expect(
      tester.getTopRight(recoveryName).dx,
      lessThan(tester.getTopLeft(delete).dx),
    );
    expect(
      tester.getTopRight(delete).dx,
      lessThan(tester.getTopLeft(recoveryPicker).dx),
    );
    _expectSameVerticalCenter(tester, [recoveryName, delete, recoveryPicker]);
    await tester.tap(delete);
    await tester.pump();
    expect(find.text('03:00'), findsNothing);
  });

  testWidgets('AMRAP expose le sélecteur principal avec ses bornes exactes', (
    tester,
  ) async {
    await _pumpEditor(tester, ExerciseGroup.amrap(id: 'amrap'));

    final effortRow = find.byKey(const Key('amrap-effort-row'));
    final effortIcon = find.descendant(
      of: effortRow,
      matching: find.byIcon(Icons.fitness_center),
    );
    final effortName = find.descendant(
      of: effortRow,
      matching: find.text('Effort'),
    );
    final edit = find.descendant(
      of: effortRow,
      matching: find.byTooltip("Modifier l'effort"),
    );
    final effortPicker = find.descendant(
      of: effortRow,
      matching: find.byType(DurationMinutesSecondsPicker),
    );
    final picker = tester.widget<DurationMinutesSecondsPicker>(effortPicker);
    expect(picker.value, const Duration(minutes: 2));
    expect(picker.minimum, const Duration(minutes: 1));
    expect(picker.maximum, const Duration(minutes: 60));
    expect(find.text("Durée de l'AMRAP"), findsNothing);
    expect(effortIcon, findsOneWidget);
    expect(effortName, findsOneWidget);
    expect(edit, findsOneWidget);
    expect(effortPicker, findsOneWidget);
    expect(
      tester.getTopLeft(effortIcon).dx,
      lessThan(tester.getTopLeft(effortName).dx),
    );
    expect(
      tester.getTopRight(effortName).dx,
      lessThan(tester.getTopLeft(edit).dx),
    );
    expect(
      tester.getTopRight(edit).dx,
      lessThan(tester.getTopLeft(effortPicker).dx),
    );
    _expectSameVerticalCenter(tester, [
      effortIcon,
      effortName,
      edit,
      effortPicker,
    ]);
    expect(find.textContaining('chaque tour terminé'), findsOneWidget);
  });

  testWidgets('EMOM borne les minutes et conserve l’effort à 60 secondes', (
    tester,
  ) async {
    await _pumpEditor(tester, ExerciseGroup.emom(id: 'emom'));

    expect(find.text('Nombre de minutes'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    final plus = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.add_circle_outline),
    );
    expect(plus.onPressed, isNotNull);
    expect(find.text('01:00'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Exercice'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Pause'), findsNothing);
  });

  testWidgets('EMOM ajoute et supprime sa récupération de transition', (
    tester,
  ) async {
    await _pumpEditor(
      tester,
      ExerciseGroup.emom(id: 'emom'),
      hasFollowingGroup: true,
    );

    final add = find.text("Ajouter une récupération après l'EMOM");
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pump();

    expect(find.text('Récupération'), findsOneWidget);
    expect(find.text('11:00'), findsOneWidget);
    expect(find.byIcon(Icons.drag_handle), findsNothing);
    final delete = find.byTooltip('Supprimer');
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pump();
    expect(find.text('11:00'), findsNothing);
  });

  testWidgets('annuler une conversion conserve tous les éléments', (
    tester,
  ) async {
    await _pumpEditor(
      tester,
      ExerciseGroup(id: 'free', name: 'Circuit', items: []),
    );
    await _chooseType(tester, GroupType.tabata);
    expect(find.text('Changer de type de groupe ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.text('Libre'), findsOneWidget);
    expect(find.text('Exercice'), findsOneWidget);
    expect(find.text('Nombre de cycles'), findsNothing);
  });

  testWidgets('le crayon temporisé masque mode et durée du dialogue', (
    tester,
  ) async {
    await _pumpEditor(tester, ExerciseGroup.tabata(id: 'tabata'));
    await tester.tap(find.byTooltip("Modifier l'effort"));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(
        of: dialog,
        matching: find.byType(DropdownButton<ExerciseInputMode>),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: dialog,
        matching: find.byType(DurationMinutesSecondsPicker),
      ),
      findsNothing,
    );
    expect(find.text('Commentaire (optionnel)'), findsOneWidget);
  });

  testWidgets('l’éditeur partagé ajoute exercice et pause en mode Libre', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpEditor(
      tester,
      ExerciseGroup(id: 'free', name: 'Circuit', items: []),
    );

    final exerciseAction = find.text('Exercice');
    await tester.ensureVisible(exerciseAction);
    await tester.tap(exerciseAction);
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), 'Squats');
    await tester.enterText(fields.at(1), '12');
    await tester.tap(find.widgetWithText(FilledButton, 'Ajouter'));
    await tester.pumpAndSettle();
    expect(find.text('Squats'), findsOneWidget);

    final restAction = find.text('Pause');
    await tester.ensureVisible(restAction);
    await tester.tap(restAction);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Ajouter'));
    await tester.pumpAndSettle();
    expect(find.text('Pause'), findsNWidgets(2));
  });
}

Future<void> _chooseType(WidgetTester tester, GroupType type) async {
  await tester.tap(find.byType(TypeSelector));
  await tester.pumpAndSettle();
  await tester.tap(find.text(type.shortLabel).last);
  await tester.pumpAndSettle();
}

void _expectSameVerticalCenter(WidgetTester tester, List<Finder> finders) {
  final expected = tester.getCenter(finders.first).dy;
  for (final finder in finders.skip(1)) {
    expect(tester.getCenter(finder).dy, closeTo(expected, 0.1));
  }
}

Future<void> _pumpEditor(
  WidgetTester tester,
  ExerciseGroup group, {
  bool hasFollowingGroup = false,
}) => tester.pumpWidget(
  MaterialApp(
    home: GroupEditor(group: group, hasFollowingGroup: hasFollowingGroup),
  ),
);
