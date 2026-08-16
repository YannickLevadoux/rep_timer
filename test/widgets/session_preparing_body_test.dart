import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/session_step.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/widgets/training_session_view.dart';

void main() {
  testWidgets('affiche les secondes et uniquement les commandes autorisées', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var pauses = 0;
    var skips = 0;
    await _pumpView(tester, onPause: () => pauses++, onSkip: () => skips++);

    expect(find.text('5'), findsOneWidget);
    expect(find.text('00:05'), findsNothing);
    expect(find.text('Prêt ?'), findsOneWidget);
    expect(find.text('Total'), findsNothing);
    expect(find.text('Prochain'), findsNothing);
    expect(find.byKey(const Key('session-progress-bar')), findsNothing);
    expect(find.byKey(const Key('previous-step-button')), findsNothing);
    expect(find.byTooltip('Progression détaillée'), findsNothing);
    expect(find.bySemanticsLabel('Début du compte à rebours'), findsOneWidget);
    expect(find.byTooltip('Passer le compte à rebours'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pause-resume-button')));
    await tester.tap(find.byKey(const Key('next-step-button')));
    expect(pauses, 1);
    expect(skips, 1);
    expect(
      tester.getSize(find.byKey(const Key('pause-resume-button'))).height,
      greaterThanOrEqualTo(48),
    );
    semantics.dispose();
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'reste lisible à 360 × 640, texte agrandi, ${brightness.name}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await _pumpView(
          tester,
          brightness: brightness,
          textScaler: const TextScaler.linear(2),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('Prêt ?'), findsOneWidget);
      },
    );
  }
}

Future<void> _pumpView(
  WidgetTester tester, {
  VoidCallback? onPause,
  VoidCallback? onSkip,
  Brightness brightness = Brightness.light,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final group = ExerciseGroup(id: 'group', name: 'Groupe', items: []);
  final step = SessionStep(
    group: group,
    roundIndex: 1,
    totalRounds: 1,
    item: TrainingItem(
      type: ItemType.exercise,
      name: 'Effort',
      repetitions: 10,
    ),
  );
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: TrainingSessionView(
        trainingName: 'Séance',
        finished: false,
        totalDuration: Duration.zero,
        onBackHome: () {},
        step: step,
        totalSteps: 1,
        preparing: true,
        preparationSeconds: 5,
        onTogglePause: onPause ?? () {},
        onSkipPreparation: onSkip ?? () {},
      ),
    ),
  );
}
