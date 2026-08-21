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

  test(
    'les sélecteurs notifient et réinitialisent l’erreur de répétitions',
    () {
      final controller = ExerciseFormController(defaultName: 'Planche');
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.repetitionsError = 'Erreur précédente';

      controller.setMode(ExerciseInputMode.duration);
      controller.setDuration(const Duration(minutes: 2));
      controller.setIconName('self_improvement');

      expect(controller.mode, ExerciseInputMode.duration);
      expect(controller.duration, const Duration(minutes: 2));
      expect(controller.iconName, 'self_improvement');
      expect(controller.repetitionsError, isNull);
      expect(notifications, 3);
    },
  );

  test('refuse ensemble nom, durée et commentaire invalides', () {
    final controller = ExerciseFormController();
    addTearDown(controller.dispose);
    controller.setMode(ExerciseInputMode.duration);
    controller.setDuration(Duration.zero);
    controller.commentController.text = 'a\nb\nc\nd';

    expect(controller.validateAndBuild(), isNull);
    expect(controller.nameError, isNotNull);
    expect(controller.commentError, isNotNull);
  });

  test('construit un exercice libre normalisé avec son icône', () {
    final controller = ExerciseFormController(defaultName: '  Gainage  ');
    addTearDown(controller.dispose);
    controller.setMode(ExerciseInputMode.freeDuration);
    controller.setIconName('self_improvement');
    controller.commentController.text = '  Lentement  ';

    final result = controller.validateAndBuild();

    expect(result, isNotNull);
    expect(result!.name, 'Gainage');
    expect(result.repetitions, isNull);
    expect(result.duration, isNull);
    expect(result.isFreeDuration, isTrue);
    expect(result.comment, 'Lentement');
    expect(result.iconName, 'self_improvement');
  });
}
