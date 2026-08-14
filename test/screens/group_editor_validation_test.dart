import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/screens/group_editor.dart';
import 'package:rep_timer/widgets/duration_minutes_seconds_picker.dart';
import 'package:rep_timer/widgets/rounds_editor.dart';

void main() {
  testWidgets('AMRAP conserve une durée invalide et résume l’erreur', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GroupEditor(group: ExerciseGroup.amrap(id: 'amrap')),
      ),
    );
    final picker = tester.widget<DurationMinutesSecondsPicker>(
      find.byType(DurationMinutesSecondsPicker),
    );
    picker.onChanged(const Duration(seconds: 30));
    await tester.pump();

    expect(find.byKey(const Key('duration-error')), findsOneWidget);
    expect(find.text('La valeur minimale est 60.'), findsOneWidget);
    final save = find.text('Enregistrer');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();

    expect(find.text('La valeur minimale est 60.'), findsWidgets);
    expect(find.text('Édition du groupe'), findsOneWidget);
    expect(
      tester
          .widget<DurationMinutesSecondsPicker>(
            find.byType(DurationMinutesSecondsPicker),
          )
          .value,
      const Duration(seconds: 30),
    );
  });

  testWidgets('les contrôles exposent les bornes Tabata et EMOM', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GroupEditor(group: ExerciseGroup.tabata(id: 't')),
      ),
    );
    var rounds = tester.widget<RoundsEditor>(find.byType(RoundsEditor));
    expect(rounds.minimum, 1);
    expect(rounds.maximum, 999);

    await tester.pumpWidget(
      MaterialApp(
        home: GroupEditor(
          key: const ValueKey('emom'),
          group: ExerciseGroup.emom(id: 'e'),
        ),
      ),
    );
    rounds = tester.widget<RoundsEditor>(find.byType(RoundsEditor));
    expect(rounds.minimum, 1);
    expect(rounds.maximum, 60);
  });
}
