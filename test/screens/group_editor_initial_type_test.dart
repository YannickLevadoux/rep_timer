import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_editor_mode.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/screens/group_editor.dart';
import 'package:rep_timer/widgets/type_selector.dart';

void main() {
  testWidgets('l’ajout commence sans type, formulaire, clavier ni action', (
    tester,
  ) async {
    await _pumpAddEditor(tester);

    expect(
      find.text('Sélectionnez un type de groupe pour commencer.'),
      findsOneWidget,
    );
    expect(find.text('Sélectionner un type'), findsOneWidget);
    expect(find.byTooltip('Aide sur les types de groupe'), findsOneWidget);
    expect(
      tester.widget<TypeSelector>(find.byType(TypeSelector)).value,
      isNull,
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Nom du groupe'), findsNothing);
    expect(find.text('Nombre de cycles'), findsNothing);
    expect(find.text('Exercice'), findsNothing);
    expect(find.text('Pause'), findsNothing);
    expect(find.text('Temps total estimé'), findsNothing);
    expect(find.text('Ajouter à la séance'), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('la première sélection des cinq types est immédiate', (
    tester,
  ) async {
    for (final type in GroupType.values) {
      await _pumpAddEditor(tester, key: ValueKey(type));
      await _chooseType(tester, type);

      expect(find.text('Changer de type de groupe ?'), findsNothing);
      expect(find.text('Ajouter à la séance'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(
        tester.widget<TypeSelector>(find.byType(TypeSelector)).value,
        type,
      );
    }
  });

  testWidgets('un changement ultérieur demande confirmation', (tester) async {
    await _pumpAddEditor(tester);
    await _chooseType(tester, GroupType.tabata);
    await _chooseType(tester, GroupType.amrap);

    expect(find.text('Changer de type de groupe ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TypeSelector>(find.byType(TypeSelector)).value,
      GroupType.tabata,
    );
  });

  testWidgets('Retour avant sélection ferme sans dialogue', (tester) async {
    await _pumpLauncher(tester);
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Ouvrir'), findsOneWidget);
    expect(find.text('Modifications non enregistrées'), findsNothing);
  });

  testWidgets('Retour après sélection propose les modifications', (
    tester,
  ) async {
    await _pumpLauncher(tester);
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await _chooseType(tester, GroupType.free);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Modifications non enregistrées'), findsOneWidget);
  });
}

Future<void> _pumpAddEditor(WidgetTester tester, {Key? key}) =>
    tester.pumpWidget(
      MaterialApp(
        home: GroupEditor(
          key: key,
          group: ExerciseGroup(id: 'new', name: '', items: []),
          mode: GroupEditorMode.add,
        ),
      ),
    );

Future<void> _chooseType(WidgetTester tester, GroupType type) async {
  await tester.tap(find.byType(TypeSelector));
  await tester.pumpAndSettle();
  await tester.tap(find.text(type.shortLabel).last);
  await tester.pumpAndSettle();
}

Future<void> _pumpLauncher(WidgetTester tester) => tester.pumpWidget(
  MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => GroupEditor(
                group: ExerciseGroup(id: 'new', name: '', items: []),
                mode: GroupEditorMode.add,
              ),
            ),
          ),
          child: const Text('Ouvrir'),
        ),
      ),
    ),
  ),
);
