import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/widgets/dialogs/repetition_sequence_dialog.dart';

void main() {
  testWidgets('ajoute, modifie, supprime et réordonne les valeurs', (
    tester,
  ) async {
    List<int>? result;
    await _pumpLauncher(
      tester,
      initial: [10, 12],
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter un tour'));
    await tester.pump();

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.at(2), '15');
    await tester.tap(find.byTooltip('Supprimer le tour').at(1));
    await tester.pump();
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.drag(
      find.byTooltip('Réordonner').first,
      const Offset(0, 120),
      touchSlopY: 0,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
    await tester.pumpAndSettle();

    expect(result, [15, 10]);
  });

  testWidgets('annuler ne modifie jamais la liste source', (tester) async {
    final source = <int>[10, 12];
    List<int>? result = [999];
    await _pumpLauncher(
      tester,
      initial: source,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '42');
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(source, [10, 12]);
  });

  testWidgets('refuse vide, texte, 0 et 1000 près de la valeur', (
    tester,
  ) async {
    await _pumpLauncher(tester, initial: [10], onResult: (_) {});
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    final field = find.byType(TextField).first;
    for (final invalid in ['', 'abc', '0', '1000']) {
      await tester.enterText(field, invalid);
      await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
      await tester.pump();
      expect(find.text('Suite de répétitions'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TextField),
          matching: find.byType(Text),
        ),
        findsWidgets,
      );
    }

    await tester.enterText(field, '999');
    await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
    await tester.pumpAndSettle();
    expect(find.text('Suite de répétitions'), findsNothing);
  });

  testWidgets(
    'une ancienne suite vide reste lisible mais ne peut être validée',
    (tester) async {
      await _pumpLauncher(tester, initial: const [], onResult: (_) {});
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Aucun tour défini'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
      await tester.pump();

      expect(find.text('Ajoute au moins un tour.'), findsOneWidget);
      expect(find.text('Suite de répétitions'), findsOneWidget);
    },
  );

  testWidgets('reste utilisable sur petite largeur avec texte agrandi', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(280, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpLauncher(
      tester,
      initial: [10, 12, 15, 12, 10],
      onResult: (_) {},
      textScale: 1.8,
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Ajouter un tour'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required List<int> initial,
  required ValueChanged<List<int>?> onResult,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
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
            onPressed: () async {
              onResult(
                await showRepetitionSequenceDialog(
                  context,
                  initialValues: initial,
                  fallbackValue: 1,
                ),
              );
            },
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    ),
  );
}
