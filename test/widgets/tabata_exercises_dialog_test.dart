import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/widgets/dialogs/tabata_exercises_dialog.dart';

void main() {
  const effort = Duration(seconds: 20);

  testWidgets('ajoute selon la préférence et refuse un nom vide', (
    tester,
  ) async {
    var prefill = false;
    List<TrainingItem>? result;
    await _pumpLauncher(
      tester,
      initial: [_exercise('Squats')],
      loadPrefill: () async => prefill,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Supprimer le cycle 1'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('Supprimer le cycle 1'),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Ajouter un cycle'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2));
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      isEmpty,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
    await tester.pump();
    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
    expect(result, isNull);

    prefill = true;
    await tester.enterText(find.byType(TextField).last, 'Fentes');
    await tester.tap(find.text('Ajouter un cycle'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      'Effort 3',
    );
  });

  testWidgets('réordonne nom, icône et commentaire ensemble', (tester) async {
    List<TrainingItem>? result;
    await _pumpLauncher(
      tester,
      initial: [
        _exercise('Squats', comment: 'Lentement'),
        _exercise('Rameur', iconName: 'rowing'),
      ],
      loadPrefill: () async => true,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorderItem!(0, 1);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
    await tester.pumpAndSettle();

    expect(result!.map((item) => item.name), ['Rameur', 'Squats']);
    expect(result!.first.iconName, 'rowing');
    expect(result!.last.comment, 'Lentement');
    expect(result!.every((item) => item.duration == effort), isTrue);
  });

  testWidgets(
    'modifie une icône et un commentaire avec les sélecteurs existants',
    (tester) async {
      List<TrainingItem>? result;
      await _pumpLauncher(
        tester,
        initial: [_exercise('Squats')],
        loadPrefill: () async => true,
        onResult: (value) => result = value,
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip("Modifier l'icône"));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.rowing));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Commentaire'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Intensité élevée');
      await tester.tap(find.widgetWithText(FilledButton, 'Valider').last);
      await tester.pumpAndSettle();
      expect(find.text('Intensité élevée'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
      await tester.pumpAndSettle();
      expect(result!.single.iconName, 'rowing');
      expect(result!.single.comment, 'Intensité élevée');
    },
  );

  testWidgets('Annuler et retour système ne modifient jamais la source', (
    tester,
  ) async {
    final source = [_exercise('Squats'), _exercise('Burpees')];
    List<TrainingItem>? result = [_exercise('sentinelle')];
    await _pumpLauncher(
      tester,
      initial: source,
      loadPrefill: () async => true,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Modifié');
    await tester.tap(find.byTooltip('Supprimer le cycle 2'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(source.map((item) => item.name), ['Squats', 'Burpees']);
  });

  testWidgets('affiche les validations françaises du nom et commentaire', (
    tester,
  ) async {
    await _pumpLauncher(
      tester,
      initial: [_exercise('n' * 51, comment: 'c' * 201)],
      loadPrefill: () async => true,
      onResult: (_) {},
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
    await tester.pump();

    expect(find.text('Maximum 50 caractères.'), findsOneWidget);
    expect(find.text('Maximum 200 caractères.'), findsOneWidget);
    expect(find.text('Éditer les exercices'), findsOneWidget);
  });

  testWidgets('reste utilisable à 360 dp avec texte agrandi', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpLauncher(
      tester,
      initial: [_exercise('Squats'), _exercise('Burpees')],
      loadPrefill: () async => true,
      onResult: (_) {},
      textScale: 1.5,
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    expect(find.text("Nom de l'exercice"), findsNothing);
    expect(tester.takeException(), isNull);
    expect(find.text('Ajouter un cycle'), findsOneWidget);
    expect(find.byTooltip('Réordonner le cycle'), findsWidgets);
  });
}

TrainingItem _exercise(String name, {String? comment, String? iconName}) =>
    TrainingItem(
      type: ItemType.exercise,
      name: name,
      duration: const Duration(seconds: 20),
      comment: comment,
      iconName: iconName,
    );

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required List<TrainingItem> initial,
  required Future<bool> Function() loadPrefill,
  required ValueChanged<List<TrainingItem>?> onResult,
  double textScale = 1,
}) => tester.pumpWidget(
  MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: Builder(
        builder: (context) => FilledButton(
          onPressed: () async => onResult(
            await showTabataExercisesDialog(
              context,
              initialExercises: initial,
              effortDuration: const Duration(seconds: 20),
              loadPrefill: loadPrefill,
            ),
          ),
          child: const Text('Ouvrir'),
        ),
      ),
    ),
  ),
);
