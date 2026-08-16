import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/session_step.dart';
import 'package:rep_timer/services/session_navigation_coordinator.dart';

void main() {
  test('désactive précédente à la première minute EMOM', () {
    final emom = ExerciseGroup.emom(id: 'emom')..rounds = 2;
    final firstMinute = SessionStep(
      group: emom,
      roundIndex: 1,
      totalRounds: 2,
      item: emom.items.single,
    );
    final secondMinute = SessionStep(
      group: emom,
      roundIndex: 2,
      totalRounds: 2,
      item: emom.items.single,
    );

    expect(canNavigateToPrevious(firstMinute, 3), isFalse);
    expect(canNavigateToPrevious(secondMinute, 4), isTrue);
  });

  test('conserve la navigation suivante normale à la dernière minute', () {
    expect(canNavigateToNext(3, 5), isTrue);
    expect(canNavigateToNext(4, 5), isFalse);
  });
}
