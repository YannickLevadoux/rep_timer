import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/session_step.dart';
import 'package:rep_timer/services/amrap_execution_state.dart';
import 'package:rep_timer/widgets/session_running_body.dart';

void main() {
  testWidgets('affiche et transmet les actions AMRAP', (tester) async {
    var recorded = 0;
    var undone = 0;
    await _pump(
      tester,
      step: _step(ExerciseGroup.amrap(id: 'amrap')),
      amrap: const AmrapExecutionSnapshot(
        activeRemaining: Duration(seconds: 49),
        currentLapDuration: Duration(seconds: 5),
        completedLapDurations: [Duration(seconds: 6)],
        buttonDelayRemaining: Duration.zero,
        canRecordLap: true,
        canUndoLastLap: true,
        limitReached: false,
        completed: false,
      ),
      onRecord: () => recorded++,
      onUndo: () => undone++,
    );

    expect(find.text('00:49'), findsOneWidget);
    expect(find.text('Tours terminés'), findsOneWidget);
    expect(find.text('Tour courant'), findsOneWidget);
    expect(find.text('Tour 1 enregistré · 00:06'), findsOneWidget);
    expect(find.byKey(const Key('round-label')), findsNothing);
    final recordButton = find.byKey(const Key('amrap-record-lap-button'));
    await tester.ensureVisible(recordButton);
    await tester.tap(recordButton);
    final undoButton = find.byKey(const Key('amrap-undo-lap-button'));
    await tester.ensureVisible(undoButton);
    await tester.tap(undoButton);
    expect(recorded, 1);
    expect(undone, 1);
  });

  testWidgets('désactive les tours et annonce la limite AMRAP', (tester) async {
    await _pump(
      tester,
      step: _step(ExerciseGroup.amrap(id: 'amrap')),
      amrap: AmrapExecutionSnapshot(
        activeRemaining: const Duration(seconds: 10),
        currentLapDuration: const Duration(seconds: 50),
        completedLapDurations: List.filled(999, const Duration(seconds: 1)),
        buttonDelayRemaining: Duration.zero,
        canRecordLap: false,
        canUndoLastLap: false,
        limitReached: true,
        completed: false,
      ),
    );

    expect(find.text('Limite de 999 tours atteinte'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('amrap-record-lap-button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('nomme les occurrences Tabata et EMOM', (tester) async {
    final tabata = ExerciseGroup.tabata(id: 'tabata')..rounds = 3;
    await _pump(tester, step: _step(tabata, round: 2, total: 3));
    expect(find.text('Cycle 2/3'), findsOneWidget);

    final emom = ExerciseGroup.emom(id: 'emom')..rounds = 10;
    await _pump(tester, step: _step(emom, round: 4, total: 10));
    expect(find.text('Minute 4/10'), findsOneWidget);
  });
}

SessionStep _step(ExerciseGroup group, {int round = 1, int total = 1}) =>
    SessionStep(
      group: group,
      roundIndex: round,
      totalRounds: total,
      item: group.items.first,
    );

Future<void> _pump(
  WidgetTester tester, {
  required SessionStep step,
  AmrapExecutionSnapshot? amrap,
  VoidCallback? onRecord,
  VoidCallback? onUndo,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SessionRunningBody(
        step: step,
        currentIndex: 0,
        totalSteps: 1,
        globalElapsed: Duration.zero,
        stepElapsed: Duration.zero,
        paused: false,
        notificationMode: NotificationMode.none,
        blinkOpacity: const AlwaysStoppedAnimation(1),
        nextStep: null,
        onPrevious: () {},
        onNext: () {},
        onComplete: () {},
        onTogglePause: () {},
        onEditComment: () {},
        onCycleNotificationMode: () {},
        amrap: amrap,
        onRecordAmrapLap: onRecord ?? () {},
        onUndoAmrapLap: onUndo ?? () {},
      ),
    ),
  ),
);
