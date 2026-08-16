import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/screens/quick_tabata_screen.dart';
import 'package:rep_timer/screens/training_session.dart';
import 'package:rep_timer/services/session_controller.dart';
import 'package:rep_timer/services/session_notification_permission_service.dart';
import 'package:rep_timer/widgets/duration_minutes_seconds_picker.dart';
import 'package:rep_timer/widgets/number_wheel_field.dart';
import 'package:rep_timer/widgets/type_selector.dart';

import '../support/fake_session_permission_platform.dart';

void main() {
  testWidgets('démarre sans type, avertissement, formulaire ni action', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(find.text('Session rapide'), findsOneWidget);
    expect(
      find.text("Cette session ne sera pas enregistrée dans Mes entraînements"),
      findsNothing,
    );
    expect(
      find.text('Sélectionnez un type de groupe pour commencer.'),
      findsOneWidget,
    );
    expect(find.text('Sélectionner un type'), findsOneWidget);
    expect(
      tester.widget<TypeSelector>(find.byType(TypeSelector)).value,
      isNull,
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Exercice'), findsNothing);
    expect(find.text('Pause'), findsNothing);
    expect(find.text('Temps total estimé'), findsNothing);
    expect(find.text('Commencer'), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('le sélecteur compact expose les cinq types', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.byType(TypeSelector));
    await tester.pumpAndSettle();
    for (final type in GroupType.values) {
      expect(find.text(type.shortLabel), findsWidgets);
    }
  });

  testWidgets('ferme l’avertissement et le réaffiche à la session suivante', (
    tester,
  ) async {
    await _pumpScreen(tester, key: const ValueKey('première'));
    expect(find.textContaining('ne sera pas enregistrée'), findsNothing);
    await _chooseType(tester, GroupType.tabata);
    expect(find.textContaining('ne sera pas enregistrée'), findsOneWidget);
    await tester.tap(find.byTooltip("Fermer l'avertissement"));
    await tester.pump();
    expect(find.textContaining('ne sera pas enregistrée'), findsNothing);

    await _pumpScreen(tester, key: const ValueKey('suivante'));
    expect(find.textContaining('ne sera pas enregistrée'), findsNothing);
    await _chooseType(tester, GroupType.free);
    expect(find.textContaining('ne sera pas enregistrée'), findsOneWidget);
    expect(find.byTooltip("Fermer l'avertissement"), findsOneWidget);
  });

  testWidgets('Retour avant sélection revient à l’accueil sans message', (
    tester,
  ) async {
    await _pumpLauncher(tester);
    await tester.tap(find.text('Ouvrir la Session rapide'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Quitter la Session rapide ?'), findsNothing);
  });

  testWidgets('Retour après sélection confirme la perte des modifications', (
    tester,
  ) async {
    await _pumpLauncher(tester);
    await tester.tap(find.text('Ouvrir la Session rapide'));
    await tester.pumpAndSettle();
    await _chooseType(tester, GroupType.free);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Quitter la Session rapide ?'), findsOneWidget);
    expect(
      find.text(
        'Cette session a été modifiée, mais elle n’a pas été lancée. '
        'Voulez-vous vraiment quitter ?',
      ),
      findsOneWidget,
    );
    expect(find.text('Rester'), findsOneWidget);
    final leave = find.widgetWithText(FilledButton, 'Retour à l’accueil');
    expect(leave, findsOneWidget);
    final leaveButton = tester.widget<FilledButton>(leave);
    expect(
      leaveButton.style?.backgroundColor?.resolve({}),
      Theme.of(tester.element(leave)).colorScheme.error,
    );

    await tester.tap(find.text('Rester'));
    await tester.pumpAndSettle();
    expect(find.text('Session rapide'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retour à l’accueil'));
    await tester.pumpAndSettle();
    expect(find.text('Accueil'), findsOneWidget);
  });

  testWidgets(
    'AMRAP est appliqué sans confirmation et masque la récupération',
    (tester) async {
      await _pumpScreen(tester);
      await _chooseType(tester, GroupType.amrap);

      expect(find.text('Changer de type de groupe ?'), findsNothing);
      expect(find.text("Durée de l'AMRAP"), findsNothing);
      expect(find.byKey(const Key('amrap-effort-row')), findsOneWidget);
      expect(find.textContaining('chaque tour terminé'), findsOneWidget);
      expect(find.text("Ajouter une récupération après l'AMRAP"), findsNothing);
      expect(find.text('02:00'), findsOneWidget);
    },
  );

  testWidgets('un changement après la première sélection reste confirmé', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await _chooseType(tester, GroupType.tabata);
    await _chooseType(tester, GroupType.amrap);

    expect(find.text('Changer de type de groupe ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TypeSelector>(find.byType(TypeSelector)).value,
      GroupType.tabata,
    );
  });

  testWidgets('AMRAP rapide lance le moteur partagé sans récupération', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await _chooseType(tester, GroupType.amrap);

    final start = find.text('Commencer');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump(const Duration(milliseconds: 100));

    final session = tester.widget<TrainingSessionScreen>(
      find.byType(TrainingSessionScreen, skipOffstage: false),
    );
    expect(session.training.groups.single.type, GroupType.amrap);
    expect(session.training.groups.single.postGroupRestDuration, isNull);
    expect(
      session.trainingChangesPersistence,
      TrainingChangesPersistence.memoryOnly,
    );
  });

  testWidgets('EMOM utilise dix minutes fixes sans récupération rapide', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await _chooseType(tester, GroupType.emom);

    final effortRow = find.byKey(const Key('emom-effort-row'));
    final minutesPicker = find.descendant(
      of: effortRow,
      matching: find.byType(NumberWheelField),
    );
    final wheel = tester.widget<NumberWheelField>(minutesPicker);
    expect(find.text('Nombre de minutes'), findsNothing);
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    expect(find.text('Effort'), findsOneWidget);
    expect(find.byTooltip("Modifier l'effort"), findsOneWidget);
    expect(wheel.value, 10);
    expect(wheel.min, 1);
    expect(wheel.max, 60);
    expect(
      find.descendant(
        of: effortRow,
        matching: find.byType(DurationMinutesSecondsPicker),
      ),
      findsNothing,
    );
    expect(find.text('10'), findsOneWidget);
    expect(find.textContaining('début de chaque minute'), findsNWidgets(2));
    expect(find.text("Ajouter une récupération après l'EMOM"), findsNothing);
    expect(find.text('10:00'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'EMOM reste utilisable en 360 × 640, texte agrandi, $brightness',
      (tester) async {
        await _pumpScreen(
          tester,
          size: const Size(360, 640),
          textScaler: const TextScaler.linear(1.5),
          brightness: brightness,
        );
        await _chooseType(tester, GroupType.emom);

        expect(tester.takeException(), isNull);
        final start = find.text('Commencer');
        await tester.ensureVisible(start);
        await tester.pump();
        expect(start.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Libre réutilise les actions génériques', (tester) async {
    await _pumpScreen(tester);
    await _chooseType(tester, GroupType.free);

    expect(find.text('Libre'), findsOneWidget);
    expect(find.text('Répétitions'), findsOneWidget);
    expect(find.text('Exercice'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
  });

  testWidgets('Commencer lance une séance temporaire', (tester) async {
    await _pumpScreen(tester);
    await _chooseType(tester, GroupType.tabata);
    await tester.tap(find.byTooltip("Fermer l'avertissement"));
    await tester.pump();
    final start = find.text('Commencer');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump(const Duration(milliseconds: 100));

    final session = tester.widget<TrainingSessionScreen>(
      find.byType(TrainingSessionScreen, skipOffstage: false),
    );
    expect(session.training.groups.single.type, GroupType.tabata);
    expect(
      session.trainingChangesPersistence,
      TrainingChangesPersistence.memoryOnly,
    );
    expect(
      find.textContaining('ne sera pas enregistrée', skipOffstage: false),
      findsOneWidget,
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'AMRAP reste utilisable sur petit écran, texte agrandi, $brightness',
      (tester) async {
        await _pumpScreen(
          tester,
          size: const Size(240, 640),
          textScaler: const TextScaler.linear(1.5),
          brightness: brightness,
        );

        await _chooseType(tester, GroupType.amrap);

        expect(tester.takeException(), isNull);
        final start = find.text('Commencer');
        await tester.ensureVisible(start);
        await tester.pump();
        expect(start.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _chooseType(WidgetTester tester, GroupType type) async {
  final dropdown = find.byType(DropdownButton<GroupType>);
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(type.shortLabel).last);
  await tester.pumpAndSettle();
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  Key? key,
  Size? size,
  TextScaler textScaler = TextScaler.noScaling,
  Brightness brightness = Brightness.light,
}) async {
  if (size != null) {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: QuickTabataScreen(
        key: key,
        permissionService: SessionNotificationPermissionService(
          platform: GrantedSessionPermissionPlatform(),
        ),
      ),
    ),
  );
}

Future<void> _pumpLauncher(WidgetTester tester) => tester.pumpWidget(
  MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Accueil')),
        body: TextButton(
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => QuickTabataScreen(
                permissionService: SessionNotificationPermissionService(
                  platform: GrantedSessionPermissionPlatform(),
                ),
              ),
            ),
          ),
          child: const Text('Ouvrir la Session rapide'),
        ),
      ),
    ),
  ),
);
