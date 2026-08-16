import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/amrap_history_data.dart';
import 'package:rep_timer/models/history_step_entry.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/widgets/training_history_group_card.dart';

void main() {
  testWidgets('détaille les tours et le partiel AMRAP', (tester) async {
    await _pump(
      tester,
      HistoryStepEntry(
        groupId: 'amrap',
        groupName: 'AMRAP',
        itemType: ItemType.exercise,
        itemName: 'Effort',
        comment: null,
        actualDuration: const Duration(seconds: 60),
        completed: true,
        amrap: AmrapHistoryData(
          configuredDuration: const Duration(seconds: 60),
          activeDuration: const Duration(seconds: 60),
          completedLapDurations: const [
            Duration(seconds: 20),
            Duration(seconds: 25),
          ],
          partialLapDuration: const Duration(seconds: 15),
          completed: true,
        ),
      ),
    );

    expect(find.text('Effort · 2 tours'), findsOneWidget);
    expect(find.text('Tour 1 · 00:20'), findsOneWidget);
    expect(find.text('Tour 2 · 00:25'), findsOneWidget);
    expect(find.text('Tour partiel · 00:15'), findsOneWidget);
    expect(find.text('Statut · Terminé'), findsOneWidget);
  });

  testWidgets('affiche le statut incomplet du groupe AMRAP', (tester) async {
    await _pump(
      tester,
      HistoryStepEntry(
        groupId: 'amrap',
        groupName: 'AMRAP',
        itemType: ItemType.exercise,
        itemName: 'Effort',
        comment: null,
        actualDuration: const Duration(seconds: 12),
        completed: false,
        amrap: AmrapHistoryData(
          configuredDuration: const Duration(seconds: 60),
          activeDuration: const Duration(seconds: 12),
          completedLapDurations: const [],
          partialLapDuration: const Duration(seconds: 12),
          completed: false,
        ),
      ),
    );

    expect(find.text('Statut · Incomplet'), findsOneWidget);
    expect(find.text('Effort · 0 tours'), findsOneWidget);
  });

  testWidgets('détaille durée et statut de chaque minute EMOM', (tester) async {
    await _pumpSteps(tester, [
      _emomMinute(index: 1, duration: const Duration(minutes: 1), done: true),
      _emomMinute(index: 2, duration: const Duration(seconds: 12), done: false),
    ]);

    expect(find.text('Minute 1/2 · Effort'), findsOneWidget);
    expect(find.text('Minute 2/2 · Effort'), findsOneWidget);
    expect(find.text('Statut · Terminé'), findsOneWidget);
    expect(find.text('Statut · Incomplet'), findsOneWidget);
    expect(find.text('01:00'), findsOneWidget);
    expect(find.text('00:12'), findsOneWidget);
  });
}

HistoryStepEntry _emomMinute({
  required int index,
  required Duration duration,
  required bool done,
}) => HistoryStepEntry(
  groupId: 'emom',
  groupName: 'EMOM',
  itemType: ItemType.exercise,
  itemName: 'Effort',
  comment: null,
  actualDuration: duration,
  completed: done,
  emomMinuteIndex: index,
);

Future<void> _pump(WidgetTester tester, HistoryStepEntry step) =>
    _pumpSteps(tester, [step]);

Future<void> _pumpSteps(WidgetTester tester, List<HistoryStepEntry> steps) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrainingHistoryGroupCard(
            groupName: steps.first.groupName,
            steps: steps,
            expanded: true,
            onToggle: () {},
          ),
        ),
      ),
    );
