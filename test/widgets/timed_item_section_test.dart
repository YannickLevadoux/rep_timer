import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/widgets/duration_minutes_seconds_picker.dart';
import 'package:rep_timer/widgets/timed_item_section.dart';

void main() {
  testWidgets('affiche l’exercice temporisé et transmet son édition', (
    tester,
  ) async {
    var editCount = 0;
    final item = TrainingItem(
      type: ItemType.exercise,
      name: 'Planche',
      iconName: 'self_improvement',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimedExerciseSection(item: item, onEdit: () => editCount++),
        ),
      ),
    );

    expect(find.text('Planche'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.byIcon(Icons.self_improvement), findsOneWidget);

    await tester.tap(find.byTooltip("Modifier l'effort"));
    expect(editCount, 1);
  });

  testWidgets('configure la durée et transmet modification et suppression', (
    tester,
  ) async {
    Duration? changedValue;
    var deleteCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimedDurationSection(
            title: 'Récupération',
            value: const Duration(minutes: 2),
            minimum: const Duration(minutes: 1),
            maximum: const Duration(minutes: 3),
            onChanged: (value) => changedValue = value,
            onDelete: () => deleteCount++,
          ),
        ),
      ),
    );

    expect(find.text('Récupération'), findsOneWidget);
    final picker = tester.widget<DurationMinutesSecondsPicker>(
      find.byType(DurationMinutesSecondsPicker),
    );
    expect(picker.minimum, const Duration(minutes: 1));
    expect(picker.maximum, const Duration(minutes: 3));

    picker.onChanged(const Duration(minutes: 2, seconds: 30));
    expect(changedValue, const Duration(minutes: 2, seconds: 30));

    await tester.tap(find.byTooltip('Supprimer'));
    expect(deleteCount, 1);
  });

  testWidgets('applique les bornes par défaut sans action de suppression', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimedDurationSection(
            title: 'Effort',
            value: const Duration(minutes: 1),
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byTooltip('Supprimer'), findsNothing);
    final picker = tester.widget<DurationMinutesSecondsPicker>(
      find.byType(DurationMinutesSecondsPicker),
    );
    expect(picker.minimum, const Duration(seconds: 1));
    expect(picker.maximum, const Duration(hours: 2, seconds: 59));
  });
}
