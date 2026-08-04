import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/screens/quick_tabata_screen.dart';
import 'package:rep_timer/screens/training_session.dart';
import 'package:rep_timer/widgets/duration_minutes_seconds_picker.dart';
import 'package:rep_timer/widgets/rounds_editor.dart';

void main() {
  testWidgets('démarre à 1 avec le bouton moins désactivé', (tester) async {
    await _pumpScreen(tester);

    expect(_rounds(tester), 1);
    expect(
      _roundsButton(tester, Icons.remove_circle_outline).onPressed,
      isNull,
    );

    tester.widget<RoundsEditor>(find.byType(RoundsEditor)).onChanged(0);
    await tester.pump();
    expect(_rounds(tester), 1);
  });

  testWidgets('le bouton plus incrémente les répétitions', (tester) async {
    await _pumpScreen(tester);

    await _tapRoundsButton(tester, Icons.add_circle_outline);

    expect(_rounds(tester), 2);
  });

  testWidgets('le bouton moins décrémente sans passer sous 1', (tester) async {
    await _pumpScreen(tester);

    await _tapRoundsButton(tester, Icons.add_circle_outline);
    await _tapRoundsButton(tester, Icons.remove_circle_outline);

    expect(_rounds(tester), 1);
    expect(
      _roundsButton(tester, Icons.remove_circle_outline).onPressed,
      isNull,
    );
  });

  testWidgets('aucun champ textuel de répétitions ne subsiste', (tester) async {
    await _pumpScreen(tester);

    expect(find.byType(RoundsEditor), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Nombre de répétitions'),
      findsNothing,
    );
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('affiche 01:20 pour 20 s, 10 s et 3 répétitions', (tester) async {
    await _pumpScreen(tester);

    await _tapRoundsButton(tester, Icons.add_circle_outline);
    await _tapRoundsButton(tester, Icons.add_circle_outline);

    expect(find.text('01:20'), findsOneWidget);
  });

  testWidgets('actualise l’estimation avec les répétitions et les durées', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(find.text('00:20'), findsOneWidget);

    await _tapRoundsButton(tester, Icons.add_circle_outline);
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

  testWidgets('la séance lancée utilise les répétitions sélectionnées', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await _tapRoundsButton(tester, Icons.add_circle_outline);
    await _tapRoundsButton(tester, Icons.add_circle_outline);

    final start = find.text('Commencer');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump();

    final session = tester.widget<TrainingSessionScreen>(
      find.byType(TrainingSessionScreen, skipOffstage: false),
    );
    expect(session.training.groups.single.rounds, 3);
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

int _rounds(WidgetTester tester) {
  return tester.widget<RoundsEditor>(find.byType(RoundsEditor)).rounds;
}

IconButton _roundsButton(WidgetTester tester, IconData icon) {
  return tester.widget<IconButton>(find.widgetWithIcon(IconButton, icon));
}

Future<void> _tapRoundsButton(WidgetTester tester, IconData icon) async {
  final button = find.widgetWithIcon(IconButton, icon);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}
