import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_editor_mode.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/screens/group_editor.dart';
import 'package:rep_timer/services/app_settings_storage.dart';
import 'package:rep_timer/widgets/duration_minutes_seconds_picker.dart';
import 'package:rep_timer/widgets/type_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('ajoute et retire un cycle en synchronisant la liste', (
    tester,
  ) async {
    await _pumpEditor(tester, ExerciseGroup.tabata(id: 'tabata'));
    await tester.tap(find.byTooltip('Augmenter Nombre de cycles par tour'));
    await tester.pumpAndSettle();
    expect(_cyclesValue(tester), '2');

    await tester.tap(find.text('Modifier les exercices'));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, 0), 'Effort');
    expect(_fieldText(tester, 1), 'Effort 2');
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Diminuer Nombre de cycles par tour'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer le dernier cycle ?'), findsNothing);
    expect(_cyclesValue(tester), '1');
  });

  testWidgets('annuler la suppression d’un exercice personnalisé le conserve', (
    tester,
  ) async {
    final group = ExerciseGroup.tabata(id: 'tabata')..rounds = 2;
    group.tabataConfig!.exercises.last.name = 'Burpees';
    await _pumpEditor(tester, group);

    await tester.tap(find.byTooltip('Diminuer Nombre de cycles par tour'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer le dernier cycle ?'), findsOneWidget);
    expect(find.textContaining('Burpees'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(_cyclesValue(tester), '2');
    await tester.tap(find.text('Modifier les exercices'));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, 1), 'Burpees');
  });

  testWidgets('rend la pause de fin obligatoire au-delà d’un tour', (
    tester,
  ) async {
    final group = ExerciseGroup.tabata(id: 'tabata');
    group.tabataConfig!.restDuration = const Duration(seconds: 17);
    group.items[1].duration = const Duration(seconds: 17);
    await _pumpEditor(tester, group);

    await tester.tap(find.byTooltip('Augmenter Nombre de tours'));
    await tester.pump();
    expect(find.text('Pause de fin de tour'), findsOneWidget);
    expect(find.text('00:17'), findsNWidgets(2));
    expect(find.byTooltip('Supprimer Pause de fin de tour'), findsNothing);

    await tester.tap(find.byTooltip('Diminuer Nombre de tours'));
    await tester.pump();
    expect(find.byTooltip('Supprimer Pause de fin de tour'), findsOneWidget);
    await tester.tap(find.byTooltip('Supprimer Pause de fin de tour'));
    await tester.pump();
    expect(find.text('Personnaliser la dernière pause'), findsOneWidget);
  });

  testWidgets('édite les deux pauses avec le dialogue partagé', (tester) async {
    await _pumpEditor(tester, ExerciseGroup.tabata(id: 'tabata'));
    await tester.tap(find.byTooltip('Modifier Pause entre les cycles'));
    await tester.pumpAndSettle();
    expect(find.text('Modifier la pause'), findsOneWidget);
    final picker = tester.widget<DurationMinutesSecondsPicker>(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(DurationMinutesSecondsPicker),
      ),
    );
    picker.onChanged(const Duration(seconds: 15));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
    await tester.pumpAndSettle();
    expect(find.text('00:15'), findsOneWidget);

    await tester.tap(find.text('Personnaliser la dernière pause'));
    await tester.pumpAndSettle();
    expect(find.text('Modifier la pause'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Modifier Pause de fin de tour'));
    await tester.pumpAndSettle();
    expect(find.text('Modifier la pause'), findsOneWidget);
  });

  testWidgets('les pauses reprennent l’encadré gris des autres groupes', (
    tester,
  ) async {
    final theme = ThemeData.light();
    await _pumpEditor(tester, ExerciseGroup.tabata(id: 'tabata'), theme: theme);

    final restContainer = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Pause entre les cycles'),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = restContainer.decoration! as BoxDecoration;
    expect(decoration.color, theme.colorScheme.surfaceContainerHighest);
    expect(decoration.borderRadius, BorderRadius.circular(8));
  });

  testWidgets('préremplit selon la préférence lors de la sélection Tabata', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      AppSettingsStorage.prefillExerciseNameKey: false,
    });
    await _pumpEditor(
      tester,
      ExerciseGroup(id: 'new', name: '', items: []),
      mode: GroupEditorMode.add,
    );
    await _selectTabata(tester);
    await tester.tap(find.text('Modifier les exercices'));
    await tester.pumpAndSettle();

    expect(_fieldText(tester, 0), isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
    await tester.pump();
    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
  });

  testWidgets('nomme silencieusement un cycle ajouté depuis le compteur', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      AppSettingsStorage.prefillExerciseNameKey: false,
    });
    ExerciseGroup? savedGroup;
    await _pumpEditor(
      tester,
      ExerciseGroup.tabata(id: 'tabata'),
      onSubmit: (group) async => savedGroup = group,
    );

    await tester.tap(find.byTooltip('Augmenter Nombre de cycles par tour'));
    await tester.pump();
    final saveButton = find.text('Enregistrer');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(savedGroup, isNotNull);
    expect(savedGroup!.tabataConfig!.exercises.map((item) => item.name), [
      'Effort',
      'Effort 2',
    ]);
    expect(find.text('Ce champ est obligatoire.'), findsNothing);
  });

  for (final mode in GroupEditorMode.values) {
    testWidgets('Tabata partage ses blocs en mode ${mode.name}', (
      tester,
    ) async {
      final needsSelection = mode != GroupEditorMode.edit;
      await _pumpEditor(
        tester,
        needsSelection
            ? ExerciseGroup(id: mode.name, name: '', items: [])
            : ExerciseGroup.tabata(id: mode.name),
        mode: mode,
      );
      if (needsSelection) await _selectTabata(tester);
      expect(find.text('Nombre de tours'), findsOneWidget);
      expect(find.text('Nombre de cycles par tour'), findsOneWidget);
      expect(find.text('Durée des efforts'), findsOneWidget);
      expect(find.text('Pause entre les cycles'), findsOneWidget);
      expect(find.text('Personnaliser la dernière pause'), findsOneWidget);
      expect(find.text(mode.actionLabel), findsOneWidget);
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('Tabata reste utilisable à 360 × 640 en $brightness', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpEditor(
        tester,
        ExerciseGroup.tabata(id: 'tabata'),
        brightness: brightness,
        textScale: 1.5,
      );

      expect(tester.takeException(), isNull);
      final save = find.text('Enregistrer');
      await tester.ensureVisible(save);
      expect(save.hitTestable(), findsOneWidget);
    });
  }
}

String _fieldText(WidgetTester tester, int index) =>
    tester.widget<TextField>(find.byType(TextField).at(index)).controller!.text;

String _cyclesValue(WidgetTester tester) => tester
    .widget<Text>(
      find
          .descendant(
            of: find.byKey(const Key('tabata-cycles-editor')),
            matching: find.byType(Text),
          )
          .at(1),
    )
    .data!;

Future<void> _selectTabata(WidgetTester tester) async {
  await tester.tap(find.byType(TypeSelector));
  await tester.pumpAndSettle();
  await tester.tap(find.text(GroupType.tabata.shortLabel).last);
  await tester.pumpAndSettle();
}

Future<void> _pumpEditor(
  WidgetTester tester,
  ExerciseGroup group, {
  GroupEditorMode mode = GroupEditorMode.edit,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  ThemeData? theme,
  Future<void> Function(ExerciseGroup group)? onSubmit,
}) => tester.pumpWidget(
  MaterialApp(
    theme: theme ?? ThemeData(brightness: brightness),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: GroupEditor(group: group, mode: mode, onSubmit: onSubmit),
  ),
);
