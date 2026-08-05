import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/widgets/exercise_form_controller.dart';

void main() {
  test(
    'un nouvel exercice conserve la première valeur comme repli interne',
    () {
      final controller = ExerciseFormController(
        defaultName: 'Squats',
        repetitionsDefinedByGroup: true,
        repetitionFallback: 12,
      );
      addTearDown(controller.dispose);

      final result = controller.validateAndBuild();

      expect(result, isNotNull);
      expect(result!.repetitions, 12);
    },
  );

  test('modifier un exercice conserve sa répétition individuelle dormante', () {
    final controller = ExerciseFormController(
      initial: TrainingItem(
        type: ItemType.exercise,
        name: 'Pompes',
        repetitions: 5,
      ),
      repetitionsDefinedByGroup: true,
      repetitionFallback: 15,
    );
    addTearDown(controller.dispose);

    final result = controller.validateAndBuild();

    expect(result, isNotNull);
    expect(result!.repetitions, 5);
  });
}
