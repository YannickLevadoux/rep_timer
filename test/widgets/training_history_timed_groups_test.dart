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
    expect(find.text('Tour 1'), findsOneWidget);
    expect(find.text('Tour 2'), findsOneWidget);
    expect(find.text('Tour partiel'), findsOneWidget);
    expect(find.text('00:15'), findsOneWidget);
  });

  testWidgets('identifie chaque minute EMOM', (tester) async {
    await _pump(
      tester,
      HistoryStepEntry(
        groupId: 'emom',
        groupName: 'EMOM',
        itemType: ItemType.exercise,
        itemName: 'Effort',
        comment: null,
        actualDuration: const Duration(minutes: 1),
        completed: true,
        emomMinuteIndex: 4,
      ),
    );

    expect(find.text('Minute 4 · Effort'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, HistoryStepEntry step) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrainingHistoryGroupCard(
            groupName: step.groupName,
            steps: [step],
            expanded: true,
            onToggle: () {},
          ),
        ),
      ),
    );
