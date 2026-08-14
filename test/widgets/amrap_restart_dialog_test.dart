import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/widgets/dialogs/amrap_restart_dialog.dart';

void main() {
  testWidgets('annule ou confirme le redémarrage AMRAP', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async =>
                result = await showAmrapRestartDialog(context),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    expect(find.text("Recommencer l'AMRAP ?"), findsOneWidget);
    expect(
      find.text('Les tours enregistrés pour cette tentative seront supprimés.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recommencer'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
