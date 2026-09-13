import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_editor_mode.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/screens/group_editor.dart';
import 'package:rep_timer/widgets/duration_minutes_seconds_picker.dart';
import 'package:rep_timer/widgets/number_wheel_field.dart';
import 'package:rep_timer/widgets/type_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('l’édition affiche son action dédiée', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GroupEditor(
          group: ExerciseGroup(id: 'g', name: 'Groupe', items: []),
          mode: GroupEditorMode.edit,
        ),
      ),
    );
    expect(find.text('Enregistrer'), findsOneWidget);
  });

  testWidgets('Tabata affiche les contrôles dans l’ordre attendu', (
    tester,
  ) async {
    await _pumpEditor(tester, ExerciseGroup.tabata(id: 'tabata'));

    final tours = find.text('Nombre de tours');
    final cycles = find.text('Nombre de cycles par tour');
    final effortRow = find.byKey(const Key('tabata-effort-row'));
    final effortIcon = find.descendant(
      of: effortRow,
      matching: find.byIcon(Icons.fitness_center),
    );
    final effortPicker = find.descendant(
      of: effortRow,
      matching: find.byType(DurationMinutesSecondsPicker),
    );
    final restRow = find.byKey(const Key('tabata-rest-row'));
    final finalRest = find.text('Personnaliser la dernière pause');
    final estimate = find.text('Temps total estimé');

    expect(tours, findsOneWidget);
    expect(cycles, findsOneWidget);
    expect(effortIcon, findsOneWidget);
    expect(find.text('Durée des efforts'), findsOneWidget);
    expect(find.text('Modifier les exercices'), findsOneWidget);
    expect(effortPicker, findsOneWidget);
    expect(
      find.descendant(
        of: restRow,
        matching: find.byType(DurationMinutesSecondsPicker),
      ),
      findsNothing,
    );
    expect(find.text('Pause entre les cycles'), findsOneWidget);
    expect(find.text('00:10'), findsOneWidget);
    expect(
      find.descendant(
        of: restRow,
        matching: find.byTooltip('Modifier Pause entre les cycles'),
      ),
      findsOneWidget,
    );

    final ordered = [tours, cycles, effortRow, restRow, finalRest, estimate];
    for (var index = 1; index < ordered.length; index++) {
      expect(
        tester.getTopLeft(ordered[index - 1]).dy,
        lessThan(tester.getTopLeft(ordered[index]).dy),
      );
    }
  });

  testWidgets('Tabata personnalise la pause de fin de tour avec un tour', (
    tester,
  ) async {
    await _pumpEditor(tester, ExerciseGroup.tabata(id: 'tabata'));
    final customize = find.text('Personnaliser la dernière pause');
    await tester.ensureVisible(customize);
    await tester.tap(customize);
    await tester.pumpAndSettle();
    expect(find.text('Modifier la pause'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
    await tester.pumpAndSettle();

    final finalRestRow = find.byKey(const Key('tabata-final-rest-row'));
    expect(find.text('Pause de fin de tour'), findsOneWidget);
    expect(
      find.descendant(
        of: finalRestRow,
        matching: find.byTooltip('Supprimer Pause de fin de tour'),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.drag_handle), findsNothing);
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

    final effortRow = find.byKey(const Key('emom-effort-row'));
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
    final minutesPicker = find.descendant(
      of: effortRow,
      matching: find.byType(NumberWheelField),
    );
    final wheel = tester.widget<NumberWheelField>(minutesPicker);
    expect(wheel.value, 10);
    expect(wheel.min, 1);
    expect(wheel.max, 60);
    expect(wheel.label, 'min');
    expect(find.text('Nombre de minutes'), findsNothing);
    expect(effortIcon, findsOneWidget);
    expect(effortName, findsOneWidget);
    expect(edit, findsOneWidget);
    expect(minutesPicker, findsOneWidget);
    expect(
      find.descendant(
        of: effortRow,
        matching: find.byType(DurationMinutesSecondsPicker),
      ),
      findsNothing,
    );
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
      lessThan(tester.getTopLeft(minutesPicker).dx),
    );
    _expectSameVerticalCenter(tester, [
      effortIcon,
      effortName,
      edit,
      minutesPicker,
    ]);
    expect(
      tester.getTopRight(minutesPicker).dx,
      closeTo(tester.getTopRight(effortRow).dx, 0.1),
    );
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('01:00'), findsNothing);
    expect(
      find.text(
        "L'exercice redémarre automatiquement au début de chaque minute.",
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, 'Exercice'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Pause'), findsNothing);

    wheel.onChanged(60);
    await tester.pump();
    expect(tester.widget<NumberWheelField>(minutesPicker).value, 60);
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

    final recoveryRow = find.byKey(const Key('emom-recovery-row'));
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
    expect(
      tester.getTopRight(recoveryPicker).dx,
      closeTo(tester.getTopRight(recoveryRow).dx, 0.1),
    );
    expect(find.text('11:00'), findsOneWidget);
    expect(find.byIcon(Icons.drag_handle), findsNothing);
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

  testWidgets('Tabata ouvre l’éditeur atomique des exercices', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpEditor(tester, ExerciseGroup.tabata(id: 'tabata'));
    await tester.tap(find.text('Modifier les exercices'));
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    expect(find.text('Éditer les exercices'), findsOneWidget);
    expect(
      find.descendant(
        of: dialog,
        matching: find.byType(DurationMinutesSecondsPicker),
      ),
      findsNothing,
    );
    expect(find.text('Cycle 1'), findsOneWidget);
    expect(find.text('Commentaire'), findsOneWidget);
    expect(find.text('Ajouter un cycle'), findsOneWidget);
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
