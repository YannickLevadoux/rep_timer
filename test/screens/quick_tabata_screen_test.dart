import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/screens/quick_tabata_screen.dart';
import 'package:rep_timer/widgets/duration_minutes_seconds_picker.dart';

void main() {
  testWidgets('affiche 01:20 pour 20 s, 10 s et 3 répétitions', (tester) async {
    await _pumpScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre de répétitions'),
      '3',
    );
    await tester.pump();

    expect(find.text('01:20'), findsOneWidget);
  });

  testWidgets('actualise l’estimation avec les répétitions et les durées', (
    tester,
  ) async {
    await _pumpScreen(tester);
    final repetitions = find.widgetWithText(TextField, 'Nombre de répétitions');

    expect(find.text('00:20'), findsOneWidget);

    await tester.enterText(repetitions, '2');
    await tester.pump();
    expect(find.text('00:50'), findsOneWidget);

    tester
        .widget<DurationMinutesSecondsPicker>(
          find.byType(DurationMinutesSecondsPicker).first,
        )
        .onChanged(const Duration(seconds: 30));
    await tester.pump();
    expect(find.text('01:10'), findsOneWidget);

    tester
        .widget<DurationMinutesSecondsPicker>(
          find.byType(DurationMinutesSecondsPicker).last,
        )
        .onChanged(const Duration(seconds: 20));
    await tester.pump();
    expect(find.text('01:20'), findsOneWidget);
  });

  testWidgets('l’aide explique l’estimation et peut être fermée', (
    tester,
  ) async {
    await _pumpScreen(tester);

    final help = find.byTooltip('Informations sur la durée estimée');
    expect(help, findsOneWidget);

    await tester.ensureVisible(help);
    await tester.pumpAndSettle();
    await tester.tap(help);
    await tester.pumpAndSettle();

    expect(find.text("À propos de l'estimation"), findsOneWidget);
    expect(find.textContaining('durée programmée'), findsOneWidget);
    expect(find.textContaining("dernière pause"), findsOneWidget);
    expect(find.textContaining('pauses manuelles'), findsOneWidget);

    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    expect(find.text("À propos de l'estimation"), findsNothing);
  });

  testWidgets('la carte ne déborde pas sur une largeur réduite', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(240, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: QuickTabataScreen(),
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Temps total estimé'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Temps total estimé'), findsOneWidget);
    expect(find.text('00:20'), findsOneWidget);
  });
}

Future<void> _pumpScreen(WidgetTester tester) {
  return tester.pumpWidget(const MaterialApp(home: QuickTabataScreen()));
}
