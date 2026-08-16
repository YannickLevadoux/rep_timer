import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/widgets/group_types_help_button.dart';

void main() {
  testWidgets('charge et rend l’aide Markdown locale', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: GroupTypesHelpButton())),
    );

    await tester.tap(find.byTooltip('Aide sur les types de groupe'));
    await tester.pumpAndSettle();

    expect(find.text('Types de groupe'), findsOneWidget);
    expect(find.text('Choisir un type'), findsOneWidget);
    for (final heading in [
      'Libre',
      'Répétitions variables',
      'Tabata',
      'AMRAP',
      'EMOM',
    ]) {
      expect(find.textContaining(heading), findsOneWidget);
    }
    expect(find.byKey(const Key('group-types-help-content')), findsOneWidget);
  });

  testWidgets('affiche un repli lisible si l’asset est illisible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GroupTypesHelpButton(
            loadContent: () => Future<String>.error('asset absent'),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Aide sur les types de groupe'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('group-types-help-error')), findsOneWidget);
    expect(
      find.text(
        "L'aide sur les types de groupe est momentanément indisponible.",
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'reste accessible sur petit écran, texte agrandi et deux thèmes',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: GroupTypesHelpButton(
                  loadContent: () => Future.value('## Libre\n\nDescription'),
                ),
              ),
            ),
          ),
        );
        expect(
          find.bySemanticsLabel('Aide sur les types de groupe'),
          findsWidgets,
        );
        await tester.tap(find.byTooltip('Aide sur les types de groupe'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Fermer'));
        await tester.pumpAndSettle();
      }
    },
  );
}
