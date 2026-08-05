import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/widgets/number_wheel_field.dart';

void main() {
  testWidgets('une saisie clavier hors borne affiche une erreur sans clamp', (
    tester,
  ) async {
    int? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NumberWheelField(
            min: 0,
            max: 59,
            value: 20,
            label: 's',
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '60');
    await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
    await tester.pump();

    expect(find.text('Valeur attendue : 0 à 59.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(changed, isNull);

    await tester.enterText(find.byType(TextField), '42');
    await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
    await tester.pumpAndSettle();

    expect(changed, 42);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('une saisie non numérique reste dans le dialogue', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NumberWheelField(
            min: 0,
            max: 59,
            value: 20,
            label: 's',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
    await tester.pump();

    expect(find.text('Saisis un nombre entier.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
