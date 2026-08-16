import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/session_checkpoint.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/screens/training_session.dart';
import 'package:rep_timer/services/session_controller.dart';
import 'package:rep_timer/widgets/session_running_body.dart';

import '../support/timed_session_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pause, reprend puis passe au premier exercice à zéro', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final harness = TimedSessionHarness(_training());
    await tester.pumpWidget(_session(harness));
    await tester.pump();

    expect(find.text('5'), findsOneWidget);
    expect(find.text('00:05'), findsNothing);

    harness.advance(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('4'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pause-resume-button')));
    harness.advance(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('4'), findsOneWidget);
    expect(find.byTooltip('Reprendre'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pause-resume-button')));
    harness.advance(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('next-step-button')));
    await tester.pump();
    expect(find.byType(SessionRunningBody), findsOneWidget);
    expect(find.byKey(const Key('pre-session-countdown')), findsNothing);
    expect(find.text('00:00'), findsOneWidget);
    final body = tester.widget<SessionRunningBody>(
      find.byType(SessionRunningBody),
    );
    expect(body.globalElapsed, Duration.zero);
    expect(body.stepElapsed, Duration.zero);
    expect(find.bySemanticsLabel('Démarrage de la séance'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Retour suspend, restaure l’état puis abandonne sans trace', (
    tester,
  ) async {
    final harness = TimedSessionHarness(_training());
    await tester.pumpWidget(_routedSession(harness));
    await tester.tap(find.text('Ouvrir'));
    await _pumpRoute(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Quitter la séance ?'), findsOneWidget);
    expect(find.text('Terminer la session'), findsNothing);
    expect(harness.tick, isNotNull);

    await tester.tap(find.text('Continuer la séance'));
    await _pumpRoute(tester);
    expect(find.byTooltip('Pause'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abandonner'));
    await tester.pumpAndSettle();

    expect(find.text('Ouvrir'), findsOneWidget);
    expect(harness.checkpoints.saved, isEmpty);
    expect(harness.checkpoints.clearCalls, 1);
    expect(harness.history.entries, isEmpty);
  });

  testWidgets('une préparation déjà pausée le reste après Continuer', (
    tester,
  ) async {
    final harness = TimedSessionHarness(_training());
    await tester.pumpWidget(_routedSession(harness));
    await tester.tap(find.text('Ouvrir'));
    await _pumpRoute(tester);
    await tester.tap(find.byKey(const Key('pause-resume-button')));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer la séance'));
    await _pumpRoute(tester);

    expect(find.byTooltip('Reprendre'), findsOneWidget);
  });
}

Future<void> _pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

Widget _session(TimedSessionHarness harness) => MaterialApp(
  home: TrainingSessionScreen(
    training: harness.training,
    controllerFactory: _factory(harness),
  ),
);

Widget _routedSession(TimedSessionHarness harness) => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => TrainingSessionScreen(
              training: harness.training,
              controllerFactory: _factory(harness),
            ),
          ),
        ),
        child: const Text('Ouvrir'),
      ),
    ),
  ),
);

SessionControllerFactory _factory(TimedSessionHarness harness) =>
    ({
      required Training training,
      required SessionCheckpoint? initialCheckpoint,
      required TrainingChangesPersistence trainingChangesPersistence,
    }) => harness.build(checkpoint: initialCheckpoint, countdownSeconds: 5);

Training _training() => Training(
  id: 'training',
  name: 'Séance',
  groups: [
    ExerciseGroup(
      id: 'group',
      name: 'Groupe',
      items: [
        TrainingItem(
          type: ItemType.exercise,
          name: 'Effort',
          duration: const Duration(seconds: 30),
        ),
      ],
    ),
  ],
  createdAt: DateTime(2026),
);
