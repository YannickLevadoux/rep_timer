import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/screens/quick_tabata_screen.dart';
import 'package:rep_timer/screens/training_session.dart';
import 'package:rep_timer/services/session_controller.dart';
import 'package:rep_timer/services/session_notification_permission_service.dart';
import 'package:rep_timer/widgets/type_selector.dart';

import '../support/fake_session_permission_platform.dart';

void main() {
  testWidgets('préremplit une Session rapide Tabata mono-exercice', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(find.text('Session rapide'), findsOneWidget);
    expect(
      find.text("Cette session ne sera pas enregistrée dans Mes entraînements"),
      findsOneWidget,
    );
    expect(find.text('Tabata'), findsNWidgets(2));
    expect(find.text('Nombre de cycles'), findsOneWidget);
    expect(find.text('Effort'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('00:20'), findsOneWidget);
    expect(find.text('Personnaliser la dernière pause'), findsNothing);
    expect(find.text('Exercice'), findsNothing);
    expect(find.text('Commencer'), findsOneWidget);
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
    await tester.tap(find.byTooltip("Fermer l'avertissement"));
    await tester.pump();
    expect(find.textContaining('ne sera pas enregistrée'), findsNothing);

    await _pumpScreen(tester, key: const ValueKey('suivante'));
    expect(find.textContaining('ne sera pas enregistrée'), findsOneWidget);
    expect(find.byTooltip("Fermer l'avertissement"), findsOneWidget);
  });

  testWidgets('AMRAP confirme le remplacement et masque la récupération', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await _chooseType(tester, GroupType.amrap);

    expect(find.text('Changer de type de groupe ?'), findsOneWidget);
    expect(find.textContaining('AMRAP, Effort et 02:00'), findsOneWidget);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.text("Durée de l'AMRAP"), findsNothing);
    expect(find.byKey(const Key('amrap-effort-row')), findsOneWidget);
    expect(find.textContaining('chaque tour terminé'), findsOneWidget);
    expect(find.text("Ajouter une récupération après l'AMRAP"), findsNothing);
    expect(find.text('02:00'), findsOneWidget);
  });

  testWidgets('AMRAP rapide lance le moteur partagé sans récupération', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await _chooseType(tester, GroupType.amrap);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

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
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.text('Nombre de minutes'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.textContaining('début de chaque minute'), findsNWidgets(2));
    expect(find.text("Ajouter une récupération après l'EMOM"), findsNothing);
    expect(find.text('10:00'), findsOneWidget);
  });

  testWidgets('Libre réutilise les actions génériques', (tester) async {
    await _pumpScreen(tester);
    await _chooseType(tester, GroupType.free);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.text('Libre'), findsOneWidget);
    expect(find.text('Répétitions'), findsOneWidget);
    expect(find.text('Exercice'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
  });

  testWidgets('Commencer lance une séance temporaire', (tester) async {
    await _pumpScreen(tester);
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
        await tester.tap(find.text('Continuer'));
        await tester.pumpAndSettle();

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
