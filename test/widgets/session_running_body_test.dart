import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/session_step.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/widgets/session_running_body.dart';

void main() {
  testWidgets('affiche un exercice en répétitions avec son chrono croissant', (
    tester,
  ) async {
    await _pumpBody(
      tester,
      step: _step(
        TrainingItem(type: ItemType.exercise, name: 'Squats', repetitions: 15),
      ),
      stepElapsed: const Duration(seconds: 12),
    );

    expect(find.text('00:12'), findsOneWidget);
    expect(find.text('× 15'), findsOneWidget);
    expect(find.text('Répétitions effectuées'), findsOneWidget);
    expect(find.text('Exercice effectué'), findsNothing);
  });

  testWidgets('affiche le compte à rebours d’un exercice chronométré', (
    tester,
  ) async {
    await _pumpBody(
      tester,
      step: _step(
        TrainingItem(
          type: ItemType.exercise,
          name: 'Gainage',
          duration: const Duration(seconds: 30),
        ),
      ),
      stepElapsed: const Duration(seconds: 7),
    );

    expect(find.text('00:23'), findsOneWidget);
    expect(find.text('Répétitions effectuées'), findsNothing);
    expect(find.text('Exercice effectué'), findsNothing);
  });

  testWidgets('affiche le chrono et la validation d’un exercice libre', (
    tester,
  ) async {
    await _pumpBody(
      tester,
      step: _step(
        TrainingItem(
          type: ItemType.exercise,
          name: 'Étirements',
          isFreeDuration: true,
        ),
      ),
      stepElapsed: const Duration(minutes: 1, seconds: 5),
    );

    expect(find.text('01:05'), findsOneWidget);
    expect(find.text('Exercice effectué'), findsOneWidget);
    expect(find.text('Répétitions effectuées'), findsNothing);
  });

  testWidgets('affiche une pause avec compte à rebours sans validation', (
    tester,
  ) async {
    await _pumpBody(
      tester,
      step: _step(
        TrainingItem(
          type: ItemType.rest,
          name: 'Pause',
          duration: const Duration(seconds: 20),
        ),
      ),
      stepElapsed: const Duration(seconds: 4),
    );

    expect(find.text('00:16'), findsOneWidget);
    expect(find.byKey(const Key('current-step-icon')), findsOneWidget);
    expect(find.text('Répétitions effectuées'), findsNothing);
    expect(find.text('Exercice effectué'), findsNothing);
    expect(find.text('Ajouter un commentaire'), findsNothing);
  });

  testWidgets('le contrôle circulaire passe de pause à reprendre', (
    tester,
  ) async {
    await _pumpBody(tester, step: _step(_repetitionExercise()));

    final pauseButton = find.byKey(const Key('pause-resume-button'));
    expect(
      find.descendant(of: pauseButton, matching: find.byIcon(Icons.pause)),
      findsOneWidget,
    );
    expect(tester.getSize(pauseButton), const Size(55, 55));
    final previousButton = find.byKey(const Key('previous-step-button'));
    final nextButton = find.byKey(const Key('next-step-button'));
    expect(tester.getSize(previousButton), const Size(55, 55));
    expect(tester.getSize(nextButton), const Size(55, 55));
    expect(
      tester.getTopLeft(pauseButton).dx - tester.getTopRight(previousButton).dx,
      8,
    );
    expect(
      tester.getTopLeft(nextButton).dx - tester.getTopRight(pauseButton).dx,
      8,
    );
    expect(
      tester.getSize(find.byKey(const Key('notification-mode-button'))),
      const Size(55, 55),
    );

    await tester.tap(pauseButton);
    await tester.pump();

    expect(
      find.descendant(of: pauseButton, matching: find.byIcon(Icons.play_arrow)),
      findsOneWidget,
    );
    final validation = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Répétitions effectuées'),
    );
    expect(validation.onPressed, isNull);
  });

  testWidgets('un appui affiche puis masque la bulle de progression', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await _pumpBody(
      tester,
      step: _step(_repetitionExercise()),
      currentIndex: 1,
      totalSteps: 4,
    );

    expect(find.bySemanticsLabel('Exercice 2 / 4'), findsOneWidget);
    expect(find.byKey(const Key('progress-bubble')), findsNothing);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0.5,
    );

    await tester.tap(find.byKey(const Key('session-progress-bar')));
    await tester.pump();

    expect(find.byKey(const Key('progress-bubble')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('progress-bubble')),
        matching: find.text('Exercice 2 / 4'),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('progress-bubble')), findsNothing);
    semantics.dispose();
  });

  testWidgets('la dernière étape annonce la fin de la séance', (tester) async {
    await _pumpBody(
      tester,
      step: _step(_repetitionExercise()),
      currentIndex: 2,
      totalSteps: 3,
      nextStep: null,
    );

    expect(find.text('Fin de la séance'), findsOneWidget);
    expect(find.text('Exercice 3 / 3'), findsNothing);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1,
    );
    final nextButton = tester.widget<IconButton>(
      find.byKey(const Key('next-step-button')),
    );
    expect(nextButton.onPressed, isNull);
  });

  testWidgets('la mise en page étroite ne produit aucun overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(280, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final longGroup = ExerciseGroup(
      id: 'long-group',
      name: 'Un nom de groupe volontairement très long pour petit écran',
      rounds: 12,
      items: [],
    );
    final current = SessionStep(
      group: longGroup,
      roundIndex: 10,
      totalRounds: 12,
      item: TrainingItem(
        type: ItemType.exercise,
        name: 'Un exercice dont le nom est lui aussi particulièrement long',
        repetitions: 20,
        comment: 'Un commentaire très long qui doit rester lisible et centré',
      ),
    );
    final next = SessionStep(
      group: longGroup,
      roundIndex: 11,
      totalRounds: 12,
      item: TrainingItem(
        type: ItemType.exercise,
        name: 'Le prochain exercice possède également un très long nom',
        repetitions: 10,
      ),
    );

    await _pumpBody(tester, step: current, nextStep: next);

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const Key('previous-step-button'))).height,
      48,
    );
    expect(
      tester.getSize(find.byKey(const Key('pause-resume-button'))),
      const Size(48, 48),
    );
    expect(
      tester.getSize(find.byKey(const Key('next-step-button'))).height,
      48,
    );
  });

  testWidgets('les commandes restent accessibles avec un texte agrandi', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(280, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final step = _step(_repetitionExercise());

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: _SessionBodyHarness(
            step: step,
            nextStep: null,
            currentIndex: 0,
            totalSteps: 1,
            stepElapsed: Duration.zero,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('previous-step-button')), findsOneWidget);
    expect(find.byKey(const Key('pause-resume-button')), findsOneWidget);
    expect(find.byKey(const Key('next-step-button')), findsOneWidget);
  });
}

TrainingItem _repetitionExercise() =>
    TrainingItem(type: ItemType.exercise, name: 'Pompes', repetitions: 10);

SessionStep _step(TrainingItem item) {
  return SessionStep(
    group: ExerciseGroup(
      id: 'group',
      name: 'Circuit',
      rounds: 3,
      items: [item],
    ),
    roundIndex: 2,
    totalRounds: 3,
    item: item,
  );
}

Future<void> _pumpBody(
  WidgetTester tester, {
  required SessionStep step,
  SessionStep? nextStep,
  int currentIndex = 0,
  int totalSteps = 3,
  Duration stepElapsed = Duration.zero,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: _SessionBodyHarness(
          step: step,
          nextStep: nextStep,
          currentIndex: currentIndex,
          totalSteps: totalSteps,
          stepElapsed: stepElapsed,
        ),
      ),
    ),
  );
  await tester.pump();
}

class _SessionBodyHarness extends StatefulWidget {
  const _SessionBodyHarness({
    required this.step,
    required this.nextStep,
    required this.currentIndex,
    required this.totalSteps,
    required this.stepElapsed,
  });

  final SessionStep step;
  final SessionStep? nextStep;
  final int currentIndex;
  final int totalSteps;
  final Duration stepElapsed;

  @override
  State<_SessionBodyHarness> createState() => _SessionBodyHarnessState();
}

class _SessionBodyHarnessState extends State<_SessionBodyHarness> {
  bool paused = false;

  @override
  Widget build(BuildContext context) {
    return SessionRunningBody(
      step: widget.step,
      nextStep: widget.nextStep,
      currentIndex: widget.currentIndex,
      totalSteps: widget.totalSteps,
      globalElapsed: const Duration(minutes: 2, seconds: 34),
      stepElapsed: widget.stepElapsed,
      paused: paused,
      notificationMode: NotificationMode.sound,
      blinkOpacity: const AlwaysStoppedAnimation(1),
      onPrevious: () {},
      onNext: () {},
      onComplete: () {},
      onTogglePause: () => setState(() => paused = !paused),
      onEditComment: () {},
      onCycleNotificationMode: () {},
    );
  }
}
