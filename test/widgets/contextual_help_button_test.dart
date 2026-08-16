import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/widgets/contextual_help_button.dart';

void main() {
  testWidgets('affiche le contenu configuré et permet de fermer le dialogue', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContextualHelpButton(
            title: 'Titre générique',
            content: Text('Contenu générique'),
            tooltip: 'Aide générique',
            icon: Icon(Icons.help_outline),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Aide générique'), findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.textContaining('Session rapide'), findsNothing);

    await tester.tap(find.byTooltip('Aide générique'));
    await tester.pumpAndSettle();

    expect(find.text('Titre générique'), findsOneWidget);
    expect(find.text('Contenu générique'), findsOneWidget);

    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();

    expect(find.text('Titre générique'), findsNothing);
  });
}
