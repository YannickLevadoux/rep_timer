import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/session_checkpoint.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/screens/session_progress.dart';
import 'package:rep_timer/screens/training_session.dart';
import 'package:rep_timer/services/session_checkpoint_storage.dart';
import 'package:rep_timer/services/session_controller.dart';
import 'package:rep_timer/services/session_notification_service.dart';
import 'package:rep_timer/services/training_history_storage.dart';
import 'package:rep_timer/services/training_storage.dart';
import 'package:rep_timer/widgets/session_finished_view.dart';
import 'package:rep_timer/widgets/session_running_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('affiche une séance vide', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TrainingSessionScreen(training: _training(0))),
    );

    expect(find.text('Séance de test'), findsOneWidget);
    expect(
      find.text('Cette séance ne contient aucun exercice.'),
      findsOneWidget,
    );
    expect(find.byType(SessionRunningBody), findsNothing);
  });

  testWidgets('transmet toutes les données de la séance active', (
    tester,
  ) async {
    await _pumpSession(tester, _training(2));

    final body = tester.widget<SessionRunningBody>(
      find.byType(SessionRunningBody),
    );
    expect(body.step.item.name, 'Exercice 1');
    expect(body.nextStep?.item.name, 'Exercice 2');
    expect(body.currentIndex, 0);
    expect(body.totalSteps, 2);
    expect(body.paused, isFalse);
    expect(body.globalElapsed, lessThan(const Duration(seconds: 1)));
    expect(body.stepElapsed, lessThan(const Duration(seconds: 1)));

    await tester.tap(find.byKey(const Key('next-step-button')));
    await tester.pump();
    expect(find.text('Exercice 2'), findsWidgets);
  });

  testWidgets('pause et reprend le clignotement de façon synchronisée', (
    tester,
  ) async {
    await _pumpSession(tester, _training(2));
    final animation = _runningBody(tester).blinkOpacity;

    await tester.pump(const Duration(milliseconds: 180));
    await tester.tap(find.byKey(const Key('pause-resume-button')));
    await tester.pump();
    final pausedValue = animation.value;
    await tester.pump(const Duration(milliseconds: 240));

    expect(_runningBody(tester).paused, isTrue);
    expect(animation.value, pausedValue);

    await tester.tap(find.byKey(const Key('pause-resume-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    expect(_runningBody(tester).paused, isFalse);
    expect(animation.value, isNot(pausedValue));
  });

  testWidgets('relaie les passages arrière-plan et premier plan', (
    tester,
  ) async {
    await _pumpSession(tester, _training(2));
    await tester.pump();
    final prefs = await SharedPreferences.getInstance();
    final initial = prefs.getString(SessionCheckpointStorage.storageKey);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final backgrounded = prefs.getString(SessionCheckpointStorage.storageKey);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    final resumed = prefs.getString(SessionCheckpointStorage.storageKey);

    expect(backgrounded, isNot(initial));
    expect(resumed, isNot(backgrounded));
    expect(_runningBody(tester).paused, isFalse);
  });

  testWidgets('ouvre la progression avec la même animation', (tester) async {
    await _pumpSession(tester, _training(2));
    final sharedOpacity = _runningBody(tester).blinkOpacity;

    await tester.tap(find.byTooltip('Progression détaillée'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final progress = tester.widget<SessionProgressScreen>(
      find.byType(SessionProgressScreen),
    );
    progress.blinkController.value = 0.5;
    await tester.pump();
    expect(sharedOpacity.value, closeTo(0.675, 0.001));
    expect(find.text('Progression (0/2)'), findsOneWidget);
  });

  testWidgets('édite et persiste le commentaire', (tester) async {
    final training = _training(1);
    SharedPreferences.setMockInitialValues({
      TrainingStorage.storageKey: jsonEncode([training.toJson()]),
    });
    await _pumpSession(tester, training);

    await tester.tap(find.text('Ajouter un commentaire'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '  Charge lourde  ');
    await tester.tap(find.text('Valider'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Charge lourde'), findsOneWidget);
    expect(training.groups.single.items.single.comment, 'Charge lourde');
    final stored = (await SharedPreferences.getInstance()).getString(
      TrainingStorage.storageKey,
    );
    expect(stored, contains('Charge lourde'));
  });

  testWidgets('restaure le commentaire si la persistance est bloquée', (
    tester,
  ) async {
    final training = _training(1);
    SharedPreferences.setMockInitialValues({
      TrainingStorage.storageKey: 'données illisibles',
    });
    await _pumpSession(tester, training);

    await tester.tap(find.text('Ajouter un commentaire'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Ne doit pas rester');
    await tester.tap(find.text('Valider'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(training.groups.single.items.single.comment, isNull);
    expect(find.text('Ne doit pas rester'), findsNothing);
    expect(find.textContaining('Commentaire non enregistré'), findsOneWidget);
  });

  testWidgets('annule puis abandonne depuis le dialogue de sortie', (
    tester,
  ) async {
    await _pumpRoutedSession(tester, _training(2));

    await _openExitDialog(tester);
    await tester.tap(find.text('Continuer la séance'));
    await tester.pump();
    expect(find.byType(TrainingSessionScreen), findsOneWidget);

    await _openExitDialog(tester);
    await tester.tap(find.text('Abandonner'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Accueil de test'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SessionCheckpointStorage.storageKey), isNull);
    expect(prefs.getString(TrainingHistoryStorage.storageKey), isNull);
  });

  testWidgets('termine de façon anticipée depuis le dialogue de sortie', (
    tester,
  ) async {
    await _pumpRoutedSession(tester, _training(2));

    await _openExitDialog(tester);
    await tester.tap(find.text('Terminer la session'));
    await _pumpUntilFound(tester, find.byType(SessionFinishedView));

    expect(find.byType(SessionFinishedView), findsOneWidget);
    final stored = (await SharedPreferences.getInstance()).getString(
      TrainingHistoryStorage.storageKey,
    );
    expect(stored, contains('incomplete'));
  });

  testWidgets('reprend à une étape depuis la revue incomplète', (tester) async {
    final training = _training(3);
    await _pumpSession(
      tester,
      training,
      checkpoint: _incompleteCheckpoint(training),
    );
    await tester.pump();

    expect(find.text('Séance incomplète'), findsOneWidget);
    await tester.tap(find.text('Reprendre à un exercice de mon choix'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(SessionProgressScreen), findsOneWidget);

    await tester.tap(find.text('Exercice 2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Continuer'));
    await _pumpUntilGone(tester, find.byType(SessionProgressScreen));

    expect(find.byType(SessionProgressScreen), findsNothing);
    expect(_runningBody(tester).step.item.name, 'Exercice 2');
    expect(_runningBody(tester).paused, isFalse);
  });

  testWidgets('clôture depuis la revue incomplète', (tester) async {
    final training = _training(3);
    await _pumpSession(
      tester,
      training,
      checkpoint: _incompleteCheckpoint(training),
    );
    await tester.pump();

    await tester.tap(find.text('Terminer la séance'));
    await _pumpUntilFound(tester, find.byType(SessionFinishedView));

    expect(find.byType(SessionFinishedView), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString(
        TrainingHistoryStorage.storageKey,
      ),
      contains('incomplete'),
    );
  });

  testWidgets('affiche la fin normale et revient à la première route', (
    tester,
  ) async {
    await _pumpRoutedSession(tester, _training(1));

    await tester.ensureVisible(find.text('Répétitions effectuées'));
    await tester.tap(find.text('Répétitions effectuées'));
    await _pumpUntilFound(tester, find.byType(SessionFinishedView));
    expect(find.byType(SessionFinishedView), findsOneWidget);

    await tester.tap(find.text("Retour à l'accueil"));
    await _pumpUntilGone(tester, find.byType(TrainingSessionScreen));
    expect(find.text('Accueil de test'), findsOneWidget);
    expect(find.byType(TrainingSessionScreen), findsNothing);
  });
}

Future<void> _pumpSession(
  WidgetTester tester,
  Training training, {
  SessionCheckpoint? checkpoint,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TrainingSessionScreen(
        training: training,
        initialCheckpoint: checkpoint,
        controllerFactory: _controllerFactory,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpRoutedSession(WidgetTester tester, Training training) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => TrainingSessionScreen(
                  training: training,
                  controllerFactory: _controllerFactory,
                ),
                settings: const RouteSettings(name: 'session'),
              ),
            ),
            child: const Text('Accueil de test'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Accueil de test'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

SessionController _controllerFactory({
  required Training training,
  required SessionCheckpoint? initialCheckpoint,
  required TrainingChangesPersistence trainingChangesPersistence,
}) {
  return SessionController(
    training: training,
    initialCheckpoint: initialCheckpoint,
    trainingChangesPersistence: trainingChangesPersistence,
    foregroundNotificationService: _FakeNotificationService(),
    enableWakelock: () async {},
    disableWakelock: () async {},
  );
}

class _FakeNotificationService extends SessionNotificationService {
  @override
  Future<void> stop() async {}
}

Future<void> _openExitDialog(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  expect(find.text('Quitter la séance ?'), findsOneWidget);
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
}

Future<void> _pumpUntilGone(WidgetTester tester, Finder finder) async {
  for (
    var attempt = 0;
    attempt < 20 && finder.evaluate().isNotEmpty;
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsNothing);
}

SessionRunningBody _runningBody(WidgetTester tester) =>
    tester.widget<SessionRunningBody>(find.byType(SessionRunningBody));

Training _training(int itemCount) => Training(
  id: 'training',
  name: 'Séance de test',
  groups: itemCount == 0
      ? []
      : [
          ExerciseGroup(
            id: 'group',
            name: 'Groupe',
            items: [
              for (var index = 1; index <= itemCount; index++)
                TrainingItem(
                  type: ItemType.exercise,
                  name: 'Exercice $index',
                  repetitions: 10,
                ),
            ],
          ),
        ],
  createdAt: DateTime(2026),
);

SessionCheckpoint _incompleteCheckpoint(Training training) => SessionCheckpoint(
  trainingId: training.id,
  currentIndex: 2,
  completed: [true, false, true],
  globalElapsed: const Duration(minutes: 2),
  stepElapsed: const Duration(seconds: 10),
  paused: true,
  savedAt: DateTime.now(),
  stepActualDurations: List.filled(3, Duration.zero),
);
