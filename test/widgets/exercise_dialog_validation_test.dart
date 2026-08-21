import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/widgets/dialogs/exercise_dialog.dart';

void main() {
  testWidgets('les répétitions invalides ne ferment pas le dialogue', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showExerciseDialog(context, defaultName: 'Pompes'),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    final name = find.widgetWithText(TextField, 'Nom');
    final comment = find.widgetWithText(TextField, 'Commentaire (optionnel)');
    expect(
      tester.widget<TextField>(name).textCapitalization,
      TextCapitalization.sentences,
    );
    expect(
      tester.widget<TextField>(comment).textCapitalization,
      TextCapitalization.sentences,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Ajouter'));
    await tester.pump();
    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);

    final repetitions = find.widgetWithText(TextField, 'Nombre de répétitions');
    await tester.enterText(repetitions, '1000');
    await tester.tap(find.widgetWithText(FilledButton, 'Ajouter'));
    await tester.pump();
    expect(find.text('La valeur maximale est 999.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.enterText(repetitions, '10');
    await tester.tap(find.widgetWithText(FilledButton, 'Ajouter'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
