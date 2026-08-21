import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/models/session_checkpoint.dart';
import 'package:rep_timer/models/session_step.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/screens/quick_session_screen.dart';
import 'package:rep_timer/screens/training_session.dart';
import 'package:rep_timer/services/session_controller.dart';
import 'package:rep_timer/services/app_settings_storage.dart';
import 'package:rep_timer/services/session_notification_permission_service.dart';
import 'package:rep_timer/services/session_notification_service.dart';
import 'package:rep_timer/services/training_history_storage.dart';
import 'package:rep_timer/services/training_storage.dart';
import 'package:rep_timer/widgets/duration_minutes_seconds_picker.dart';
import 'package:rep_timer/widgets/number_wheel_field.dart';
import 'package:rep_timer/widgets/session_finished_view.dart';
import 'package:rep_timer/widgets/type_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_session_permission_platform.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('demande le type avant de charger un modèle de groupe', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(find.text('Session rapide'), findsOneWidget);
    expect(find.textContaining('ne sera pas enregistrée'), findsNothing);
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
    expect(find.text('Effort'), findsNothing);
    expect(find.text('Pause'), findsNothing);
    expect(find.text('Temps total estimé'), findsNothing);
    expect(find.text('Commencer'), findsNothing);
    expect(find.textContaining('Préparation :'), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('Tabata charge les valeurs historiques après sélection', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await _selectType(tester, GroupType.tabata);

    expect(find.textContaining('ne sera pas enregistrée'), findsOneWidget);
    expect(find.text('Tabata'), findsWidgets);
    expect(find.text('Effort'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Nombre de cycles'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(
      _duration(tester, const Key('tabata-effort-row')).value,
      const Duration(seconds: 20),
    );
    expect(
      _duration(tester, const Key('tabata-rest-row')).value,
      const Duration(seconds: 10),
    );
    expect(find.text('00:20'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
  });

  testWidgets('le sélecteur expose les cinq types', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.byType(TypeSelector));
    await tester.pumpAndSettle();
    for (final type in GroupType.values) {
      expect(find.text(type.shortLabel), findsWidgets);
    }
  });

  testWidgets('Tabata estime huit cycles à 03:50 sans dernière pause', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await _selectType(tester, GroupType.tabata);

    for (var index = 1; index < 8; index++) {
      await tester.tap(find.byTooltip('Augmenter Nombre de cycles'));
      await tester.pump();
    }

    expect(find.text('8'), findsOneWidget);
    expect(find.text('03:50'), findsOneWidget);
    expect(find.text('Personnaliser la dernière pause'), findsNothing);
  });

  testWidgets('ferme l’avertissement et le réaffiche à la session suivante', (
    tester,
  ) async {
    await _pumpScreen(tester, key: const ValueKey('première'));
    expect(find.textContaining('ne sera pas enregistrée'), findsNothing);
    await _selectType(tester, GroupType.tabata);
    expect(find.textContaining('ne sera pas enregistrée'), findsOneWidget);
    await tester.tap(find.byTooltip("Fermer l'avertissement"));
    await tester.pump();
    expect(find.textContaining('ne sera pas enregistrée'), findsNothing);

    await _pumpScreen(tester, key: const ValueKey('suivante'));
    expect(find.textContaining('ne sera pas enregistrée'), findsNothing);
    await _selectType(tester, GroupType.free);
    expect(find.textContaining('ne sera pas enregistrée'), findsOneWidget);
    expect(find.byTooltip("Fermer l'avertissement"), findsOneWidget);
  });

  testWidgets('Retour sans modification revient à l’accueil sans message', (
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

  testWidgets('Retour après modification confirme la perte des changements', (
    tester,
  ) async {
    await _pumpLauncher(tester);
    await tester.tap(find.text('Ouvrir la Session rapide'));
    await tester.pumpAndSettle();
    await _selectType(tester, GroupType.free);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Quitter la Session rapide ?'), findsOneWidget);
    expect(find.text('Rester'), findsOneWidget);
    expect(find.text('Retour à l’accueil'), findsOneWidget);

    await tester.tap(find.text('Rester'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Modifier le nom du groupe'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retour à l’accueil'));
    await tester.pumpAndSettle();
    expect(find.text('Accueil'), findsOneWidget);
  });

  testWidgets('AMRAP réutilise 02:00 et masque la récupération', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await _selectType(tester, GroupType.amrap);

    expect(find.byKey(const Key('amrap-effort-row')), findsOneWidget);
    expect(find.textContaining('chaque tour terminé'), findsOneWidget);
    expect(find.text("Ajouter une récupération après l'AMRAP"), findsNothing);
    expect(find.text('02:00'), findsOneWidget);
  });

  testWidgets('EMOM utilise dix minutes fixes sans récupération', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await _selectType(tester, GroupType.emom);

    final effortRow = find.byKey(const Key('emom-effort-row'));
    final minutesPicker = find.descendant(
      of: effortRow,
      matching: find.byType(NumberWheelField),
    );
    final wheel = tester.widget<NumberWheelField>(minutesPicker);
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    expect(find.text('Effort'), findsOneWidget);
    expect(find.byTooltip("Modifier l'effort"), findsOneWidget);
    expect(wheel.value, 10);
    expect(wheel.min, 1);
    expect(wheel.max, 60);
    expect(find.text("Ajouter une récupération après l'EMOM"), findsNothing);
    expect(find.text('10:00'), findsOneWidget);
  });

  for (final type in [GroupType.tabata, GroupType.amrap, GroupType.emom]) {
    testWidgets('${type.name} lance le moteur partagé sans récupération', (
      tester,
    ) async {
      await _pumpScreen(tester);
      await _selectType(tester, type);

      await _start(tester);
      final session = _session(tester);
      final steps = buildSessionSteps(session.training);

      expect(session.training.groups.single.type, type);
      expect(session.training.groups.single.finalRestDuration, isNull);
      expect(session.training.groups.single.postGroupRestDuration, isNull);
      expect(
        session.trainingChangesPersistence,
        TrainingChangesPersistence.memoryOnly,
      );
      expect(steps.where((step) => step.item.type == ItemType.rest), isEmpty);
      expect(steps, hasLength(type == GroupType.emom ? 10 : 1));
      if (type == GroupType.emom) {
        expect(find.text('Minute 1/10', skipOffstage: false), findsOneWidget);
      }
    });
  }

  testWidgets('charge le compte à rebours au lancement rapide', (tester) async {
    SharedPreferences.setMockInitialValues({
      AppSettingsStorage.preSessionCountdownSecondsKey: 7,
    });
    await _pumpScreen(tester);
    await _selectType(tester, GroupType.tabata);

    expect(find.text('Préparation : 7 sec'), findsOneWidget);
    expect(
      tester
          .widget<Switch>(
            find.byKey(const Key('pre-session-preparation-switch')),
          )
          .value,
      isTrue,
    );
    await _start(tester);

    expect(_session(tester).preSessionCountdownSeconds, 7);
  });

  testWidgets(
    'désactiver la préparation rapide ne modifie pas les paramètres',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        AppSettingsStorage.preSessionCountdownSecondsKey: 7,
      });
      await _pumpScreen(tester);
      await _selectType(tester, GroupType.tabata);

      await tester.tap(find.byKey(const Key('pre-session-preparation-switch')));
      await tester.pump();
      await _start(tester);

      expect(_session(tester).preSessionCountdownSeconds, 0);
      expect(await AppSettingsStorage().loadPreSessionCountdownSeconds(), 7);
    },
  );

  for (final type in [GroupType.free, GroupType.variableRepetitions]) {
    testWidgets('${type.name} peut être configuré et lancé', (tester) async {
      await _pumpScreen(tester);
      await _configureRepetitionExercise(tester, type);

      await _start(tester);
      final session = _session(tester);

      expect(session.training.groups.single.type, type);
      expect(buildSessionSteps(session.training), hasLength(1));
      expect(
        session.trainingChangesPersistence,
        TrainingChangesPersistence.memoryOnly,
      );
    });
  }

  testWidgets('l’effort temporisé réutilise le formulaire contraint partagé', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await _selectType(tester, GroupType.tabata);
    await tester.tap(find.byTooltip("Modifier l'effort"));
    await tester.pumpAndSettle();

    expect(find.text("Toucher pour changer l'icône"), findsOneWidget);
    expect(find.text('Commentaire (optionnel)'), findsOneWidget);
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.first, 'Burpees');
    await tester.enterText(fields.last, 'Intensité élevée');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.text('Burpees'), findsOneWidget);
  });

  testWidgets('Préparation bloque un double lancement', (tester) async {
    final platform = _DelayedPermissionPlatform();
    await _pumpScreen(
      tester,
      permissionService: SessionNotificationPermissionService(
        platform: platform,
      ),
    );
    await _selectType(tester, GroupType.tabata);

    final start = find.text('Commencer');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump();
    expect(find.text('Préparation…'), findsOneWidget);
    expect(platform.statusCalls, 1);

    await tester.tap(find.text('Préparation…'));
    await tester.pump();
    expect(platform.statusCalls, 1);

    platform.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.byType(TrainingSessionScreen, skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('le lancement ne crée aucun entraînement enregistré', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await _selectType(tester, GroupType.tabata);
    await _start(tester);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(TrainingStorage.storageKey), isNull);
    expect(_session(tester).training.id, startsWith('quick_'));
  });

  testWidgets('une fin normale crée une entrée d’historique terminée', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await _configureRepetitionExercise(tester, GroupType.free);
    await _start(tester);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.text('Répétitions effectuées'));
    await tester.tap(find.text('Répétitions effectuées'));
    await _pumpUntilFound(tester, find.byType(SessionFinishedView));

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(TrainingHistoryStorage.storageKey),
      contains('completed'),
    );
    expect(prefs.getString(TrainingStorage.storageKey), isNull);
  });

  testWidgets('une fin anticipée crée une entrée d’historique incomplète', (
    tester,
  ) async {
    await _pumpScreen(tester);
    await _configureRepetitionExercise(tester, GroupType.free);
    await tester.tap(find.byTooltip('Plus de répétitions'));
    await tester.pump();
    await _start(tester);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Terminer la session'));
    await _pumpUntilFound(tester, find.byType(SessionFinishedView));

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(TrainingHistoryStorage.storageKey),
      contains('incomplete'),
    );
    expect(prefs.getString(TrainingStorage.storageKey), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('reste utilisable en 360 × 640, texte agrandi, $brightness', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        size: const Size(360, 640),
        textScaler: const TextScaler.linear(1.5),
        brightness: brightness,
      );
      await _selectType(tester, GroupType.emom);

      expect(tester.takeException(), isNull);
      final start = find.text('Commencer');
      await tester.ensureVisible(start);
      await tester.pump();
      expect(start.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

DurationMinutesSecondsPicker _duration(WidgetTester tester, Key rowKey) =>
    tester.widget<DurationMinutesSecondsPicker>(
      find.descendant(
        of: find.byKey(rowKey),
        matching: find.byType(DurationMinutesSecondsPicker),
      ),
    );

Future<void> _selectType(WidgetTester tester, GroupType type) async {
  final selector = tester.widget<TypeSelector>(find.byType(TypeSelector));
  if (selector.value == type) return;
  final dropdown = find.byType(DropdownButton<GroupType>);
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(type.shortLabel).last);
  await tester.pumpAndSettle();
  if (find.text('Changer de type de groupe ?').evaluate().isNotEmpty) {
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
  }
}

Future<void> _start(WidgetTester tester) async {
  final start = find.text('Commencer');
  await tester.ensureVisible(start);
  await tester.pumpAndSettle();
  final button = tester.widget<FilledButton>(
    find.ancestor(of: start, matching: find.byType(FilledButton)),
  );
  button.onPressed!();
  await tester.pump(const Duration(milliseconds: 100));
}

TrainingSessionScreen _session(WidgetTester tester) =>
    tester.widget<TrainingSessionScreen>(
      find.byType(TrainingSessionScreen, skipOffstage: false),
    );

Future<void> _configureRepetitionExercise(
  WidgetTester tester,
  GroupType type,
) async {
  await _selectType(tester, type);
  await tester.tap(find.text('Exercice'));
  await tester.pumpAndSettle();
  final fields = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(fields.first, 'Squats');
  if (type == GroupType.free) {
    await tester.enterText(fields.at(1), '12');
  }
  await tester.tap(find.text('Ajouter'));
  await tester.pumpAndSettle();
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  Key? key,
  Size? size,
  TextScaler textScaler = TextScaler.noScaling,
  Brightness brightness = Brightness.light,
  SessionNotificationPermissionService? permissionService,
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
      home: QuickSessionScreen(
        key: key,
        controllerFactory: _controllerFactory,
        permissionService:
            permissionService ??
            SessionNotificationPermissionService(
              platform: GrantedSessionPermissionPlatform(),
            ),
      ),
    ),
  );
}

SessionController _controllerFactory({
  required Training training,
  required SessionCheckpoint? initialCheckpoint,
  required TrainingChangesPersistence trainingChangesPersistence,
}) => SessionController(
  training: training,
  initialCheckpoint: initialCheckpoint,
  trainingChangesPersistence: trainingChangesPersistence,
  foregroundNotificationService: _FakeNotificationService(),
  enableWakelock: () async {},
  disableWakelock: () async {},
);

class _FakeNotificationService extends SessionNotificationService {
  @override
  Future<void> stop() async {}
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
              builder: (_) => QuickSessionScreen(
                controllerFactory: _controllerFactory,
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

class _DelayedPermissionPlatform
    implements SessionNotificationPermissionPlatform {
  final _status = Completer<SessionNotificationPermissionStatus>();
  int statusCalls = 0;

  void complete() =>
      _status.complete(SessionNotificationPermissionStatus.granted);

  @override
  void initialize() {}

  @override
  Future<SessionNotificationPermissionStatus> notificationPermissionStatus() {
    statusCalls++;
    return _status.future;
  }

  @override
  Future<SessionNotificationPermissionStatus>
  requestNotificationPermission() async =>
      SessionNotificationPermissionStatus.granted;

  @override
  Future<bool> openNotificationSettings() async => true;

  @override
  Future<BatteryOptimizationStatus> batteryOptimizationStatus() async =>
      BatteryOptimizationStatus.exempt;

  @override
  Future<void> requestBatteryOptimizationExemption() async {}
}
