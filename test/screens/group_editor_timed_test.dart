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

    expect(find.text('02:00'), findsNWidgets(2));
    await tester.tap(find.text("Ajouter une récupération après l'AMRAP"));
    await tester.pump();
    expect(find.text('03:00'), findsOneWidget);
    await tester.tap(find.byTooltip('Supprimer'));
    await tester.pump();
    expect(find.text('03:00'), findsNothing);
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

Future<void> _pumpEditor(
  WidgetTester tester,
  ExerciseGroup group, {
  bool hasFollowingGroup = false,
}) => tester.pumpWidget(
  MaterialApp(
    home: GroupEditor(group: group, hasFollowingGroup: hasFollowingGroup),
  ),
);
