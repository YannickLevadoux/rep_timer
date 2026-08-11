import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/screens/quick_tabata_screen.dart';
import 'package:rep_timer/screens/training_session.dart';
import 'package:rep_timer/services/session_notification_permission_service.dart';
import 'package:rep_timer/widgets/duration_minutes_seconds_picker.dart';
import 'package:rep_timer/widgets/number_wheel_field.dart';
import 'package:rep_timer/widgets/rounds_editor.dart';

import '../support/fake_session_permission_platform.dart';

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

  testWidgets('Work et Pause alignent libellé à gauche et saisie à droite', (
    tester,
  ) async {
    await _pumpScreen(tester, surfaceSize: const Size(360, 640));

    final pickers = find.byType(DurationMinutesSecondsPicker);
    _expectCompactDurationRow(tester, find.text('Work'), pickers.at(0));
    _expectCompactDurationRow(tester, find.text('Pause'), pickers.at(1));

    final dividers = find.byType(Divider);
    expect(dividers, findsNWidgets(2));
    for (var index = 0; index < 2; index++) {
      final divider = tester.widget<Divider>(dividers.at(index));
      expect(divider.height, 10);
      expect(divider.thickness, 1);
    }

    expect(
      tester.getCenter(dividers.at(0)).dy,
      allOf(
        greaterThan(tester.getBottomLeft(pickers.at(0)).dy),
        lessThan(tester.getTopLeft(pickers.at(1)).dy),
      ),
    );
    expect(
      tester.getCenter(dividers.at(1)).dy,
      allOf(
        greaterThan(tester.getBottomLeft(pickers.at(1)).dy),
        lessThan(tester.getTopLeft(find.byType(RoundsEditor)).dy),
      ),
    );
  });

  testWidgets('conserve les dimensions des roues de durée partagées', (
    tester,
  ) async {
    await _pumpScreen(tester, surfaceSize: const Size(360, 640));

    final wheels = find.byType(NumberWheelField);
    expect(wheels, findsNWidgets(4));
    for (var index = 0; index < 4; index++) {
      final wheel = find.descendant(
        of: wheels.at(index),
        matching: find.byType(ListWheelScrollView),
      );
      expect(tester.getSize(wheel), const Size(64, 120));
    }
  });

  testWidgets('compacte la carte sans réduire la durée ni son aide', (
    tester,
  ) async {
    await _pumpScreen(tester, surfaceSize: const Size(360, 640));

    final card = find.ancestor(
      of: find.text('Temps total estimé'),
      matching: find.byType(Card),
    );
    expect(tester.getSize(card).height, lessThan(88));

    final durationText = tester.widget<Text>(find.text('00:20'));
    expect(durationText.style?.fontSize, 18);
    expect(durationText.style?.fontWeight, FontWeight.bold);

    final help = find.byTooltip('Informations sur la durée estimée');
    final helpSize = tester.getSize(help);
    expect(helpSize, const Size.square(40));
  });

  testWidgets('Commencer est visible et lance la séance sur 360 × 640', (
    tester,
  ) async {
    await _pumpScreen(tester, surfaceSize: const Size(360, 640));

    final start = find.widgetWithText(FilledButton, 'Commencer');
    final scrollable = Scrollable.of(tester.element(start));
    expect(scrollable.position.pixels, 0);

    final buttonRect = tester.getRect(start);
    expect(buttonRect.top, greaterThanOrEqualTo(0));
    expect(buttonRect.bottom, lessThanOrEqualTo(640));
    expect(start.hitTestable(), findsOneWidget);

    await tester.tap(start);
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byType(TrainingSessionScreen, skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('répartit la hauteur disponible entre les sections', (
    tester,
  ) async {
    await _pumpScreen(tester, surfaceSize: const Size(360, 640));
    final compactGaps = _verticalSectionGaps(tester);

    await tester.binding.setSurfaceSize(const Size(360, 800));
    await tester.pump();

    final expandedGaps = _verticalSectionGaps(tester);
    for (var index = 0; index < compactGaps.length; index++) {
      expect(expandedGaps[index], greaterThan(compactGaps[index]));
    }

    final start = find.widgetWithText(FilledButton, 'Commencer');
    final scrollable = Scrollable.of(tester.element(start));
    expect(scrollable.position.maxScrollExtent, 0);
    expect(tester.getBottomLeft(start).dy, closeTo(792, 0.1));
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
    await tester.pump(const Duration(milliseconds: 100));

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
    await _pumpScreen(
      tester,
      surfaceSize: const Size(240, 640),
      textScaler: const TextScaler.linear(1.5),
    );

    final work = find.text('Work');
    final workPicker = find.byType(DurationMinutesSecondsPicker).first;
    expect(
      tester.getBottomLeft(work).dy,
      lessThanOrEqualTo(tester.getTopLeft(workPicker).dy),
    );

    final start = find.widgetWithText(FilledButton, 'Commencer');
    final scrollable = Scrollable.of(tester.element(start));
    expect(scrollable.position.maxScrollExtent, greaterThan(0));

    expect(tester.takeException(), isNull);
    expect(find.text('Temps total estimé'), findsOneWidget);
    expect(find.text('00:20'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(start.hitTestable(), findsOneWidget);
  });

  testWidgets('le nom vide reste refusé', (tester) async {
    await _pumpScreen(tester);

    await tester.enterText(find.byType(TextField), '   ');
    final start = find.widgetWithText(FilledButton, 'Commencer');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump();

    expect(find.text('Ce champ est obligatoire.'), findsOneWidget);
    expect(find.byType(TrainingSessionScreen), findsNothing);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  Size? surfaceSize,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  if (surfaceSize != null) {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  return tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: QuickTabataScreen(
        permissionService: SessionNotificationPermissionService(
          platform: GrantedSessionPermissionPlatform(),
        ),
      ),
    ),
  );
}

void _expectCompactDurationRow(
  WidgetTester tester,
  Finder label,
  Finder picker,
) {
  expect(tester.getCenter(label).dy, closeTo(tester.getCenter(picker).dy, 0.1));
  expect(tester.getTopLeft(label).dx, closeTo(16, 0.1));
  expect(tester.getTopRight(picker).dx, closeTo(344, 0.1));
}

List<double> _verticalSectionGaps(WidgetTester tester) {
  final pickers = find.byType(DurationMinutesSecondsPicker);
  final rounds = find.byType(RoundsEditor);
  final card = find.ancestor(
    of: find.text('Temps total estimé'),
    matching: find.byType(Card),
  );
  final start = find.widgetWithText(FilledButton, 'Commencer');

  return [
    tester.getTopLeft(pickers.at(0)).dy -
        tester.getBottomLeft(find.byType(TextField)).dy,
    tester.getTopLeft(pickers.at(1)).dy -
        tester.getBottomLeft(pickers.at(0)).dy,
    tester.getTopLeft(rounds).dy - tester.getBottomLeft(pickers.at(1)).dy,
    tester.getTopLeft(card).dy - tester.getBottomLeft(rounds).dy,
    tester.getTopLeft(start).dy - tester.getBottomLeft(card).dy,
  ];
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
