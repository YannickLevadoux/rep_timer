import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/widgets/dialogs/comment_dialog.dart';

void main() {
  testWidgets('refuse quatre lignes et conserve le dialogue ouvert', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showCommentDialog(context, initialComment: ''),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).textCapitalization,
      TextCapitalization.sentences,
    );
    await tester.enterText(find.byType(TextField), 'un\ndeux\ntrois\nquatre');
    await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
    await tester.pump();

    expect(find.text('Maximum 3 lignes.'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('refuse 201 caractères et affiche le compteur', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showCommentDialog(context, initialComment: ''),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a' * 201);
    await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
    await tester.pump();

    expect(find.text('Maximum 200 caractères.'), findsOneWidget);
    expect(find.text('201/200'), findsOneWidget);
  });
}
