import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/controllers/group_editor_controller.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/models/training_item.dart';

void main() {
  test('un ajout classique démarre en Libre et reste transactionnel', () {
    final source = ExerciseGroup(id: 'group', name: '', items: []);
    final controller = GroupEditorController(source);

    expect(controller.group.type, GroupType.free);
    controller.nameController.text = 'Circuit';
    controller.addItem(
      TrainingItem(type: ItemType.exercise, name: 'Squats', repetitions: 10),
    );

    expect(controller.hasUnsavedChanges, isTrue);
    expect(source.name, isEmpty);
    expect(source.items, isEmpty);
    expect(controller.save().name, 'Circuit');
    controller.dispose();
  });

  test('initialise les trois groupes temporisés avec leurs bornes', () {
    final controller = GroupEditorController(
      ExerciseGroup(id: 'group', name: '', items: []),
    );

    controller.switchType(GroupType.tabata);
    expect(controller.group.name, 'Tabata');
    expect(controller.group.items.map((item) => item.duration), [
      const Duration(seconds: 20),
      const Duration(seconds: 10),
    ]);

    controller.switchType(GroupType.amrap);
    expect(controller.group.name, 'AMRAP');
    expect(controller.group.items.single.duration, const Duration(minutes: 2));

    controller.switchType(GroupType.emom);
    expect(controller.group.name, 'EMOM');
    expect(controller.group.rounds, 10);
    expect(controller.group.items.single.duration, const Duration(minutes: 1));
    controller.dispose();
  });

  test('restaure le brouillon de chaque type visité', () {
    final controller = GroupEditorController(ExerciseGroup.tabata(id: 'g'));
    controller.setRounds(8);
    controller.nameController.text = 'Intervalles';
    controller.switchType(GroupType.amrap);
    controller.setEffortDuration(const Duration(minutes: 12));
    controller.switchType(GroupType.tabata);

    expect(controller.group.rounds, 8);
    expect(controller.nameController.text, 'Intervalles');
    controller.switchType(GroupType.amrap);
    expect(controller.group.items.single.duration, const Duration(minutes: 12));
    controller.dispose();
  });

  test('restaure le brouillon EMOM sans muter le groupe original', () {
    final source = ExerciseGroup.emom(id: 'g');
    final controller = GroupEditorController(source);
    controller.setRounds(24);
    controller.nameController.text = 'Cardio minute';
    controller.updateTimedExercise(
      TrainingItem(
        type: ItemType.exercise,
        name: 'Burpees',
        repetitions: 12,
        comment: 'Rester fluide',
        iconName: 'rowing',
      ),
    );

    controller.switchType(GroupType.free);
    controller.switchType(GroupType.emom);

    expect(controller.group.rounds, 24);
    expect(controller.nameController.text, 'Cardio minute');
    expect(controller.group.items.single.name, 'Burpees');
    expect(controller.group.items.single.duration, const Duration(minutes: 1));
    expect(source.rounds, 10);
    expect(source.name, 'EMOM');
    expect(source.items.single.name, 'Effort');
    controller.dispose();
  });

  test('les récupérations optionnelles sont ajoutées et supprimées', () {
    final controller = GroupEditorController(ExerciseGroup.tabata(id: 'g'));
    controller.setFinalRestEnabled(true);
    controller.setFinalRestDuration(const Duration(seconds: 17));
    expect(controller.group.finalRestDuration, const Duration(seconds: 17));
    controller.setFinalRestEnabled(false);
    expect(controller.group.finalRestDuration, isNull);

    controller.switchType(GroupType.emom);
    controller.setPostGroupRestEnabled(true);
    expect(
      controller.group.postGroupRestDuration,
      ExerciseGroup.defaultPostGroupRest,
    );
    controller.setPostGroupRestEnabled(false);
    expect(controller.group.postGroupRestDuration, isNull);
    controller.dispose();
  });

  test('le formulaire contraint conserve un exercice chronométré', () {
    final controller = GroupEditorController(ExerciseGroup.emom(id: 'g'));
    controller.updateTimedExercise(
      TrainingItem(
        type: ItemType.exercise,
        name: 'Burpees',
        repetitions: 12,
        isFreeDuration: true,
        comment: 'Régulier',
        iconName: 'rowing',
      ),
    );

    final effort = controller.group.items.single;
    expect(effort.name, 'Burpees');
    expect(effort.duration, const Duration(minutes: 1));
    expect(effort.repetitions, isNull);
    expect(effort.isFreeDuration, isFalse);
    expect(effort.comment, 'Régulier');
    expect(effort.iconName, 'rowing');
    controller.dispose();
  });

  test('l’effort AMRAP conserve sa durée principale pendant l’édition', () {
    final controller = GroupEditorController(ExerciseGroup.amrap(id: 'g'));
    controller.setEffortDuration(const Duration(minutes: 12));
    controller.updateTimedExercise(
      TrainingItem(
        type: ItemType.exercise,
        name: 'Burpees',
        repetitions: 20,
        isFreeDuration: true,
        comment: 'Rester fluide',
        iconName: 'rowing',
      ),
    );

    final effort = controller.group.items.single;
    expect(effort.name, 'Burpees');
    expect(effort.duration, const Duration(minutes: 12));
    expect(effort.repetitions, isNull);
    expect(effort.isFreeDuration, isFalse);
    expect(effort.comment, 'Rester fluide');
    expect(effort.iconName, 'rowing');
    controller.dispose();
  });

  test('crée les brouillons Libre et Variables depuis Tabata', () {
    final controller = GroupEditorController(ExerciseGroup.tabata(id: 'g'));
    controller.switchType(GroupType.free);
    expect(controller.group.name, 'Groupe libre');
    controller.switchType(GroupType.variableRepetitions);
    expect(controller.group.repetitionSequence, [1]);
    expect(controller.group.name, 'Groupe libre');
    controller.dispose();
  });

  test('centralise toutes les mutations des éléments génériques', () {
    final controller = GroupEditorController(
      ExerciseGroup(
        id: 'g',
        name: 'Circuit',
        items: [
          TrainingItem(
            type: ItemType.exercise,
            name: 'Squats',
            repetitions: 10,
          ),
          TrainingItem(
            type: ItemType.rest,
            name: 'Pause',
            duration: const Duration(seconds: 10),
          ),
        ],
      ),
    );
    controller.updateRest(1, const Duration(seconds: 20));
    controller.updateExercise(
      0,
      TrainingItem(
        type: ItemType.exercise,
        name: 'Fentes',
        duration: const Duration(seconds: 30),
      ),
    );
    controller.reorderItems(1, 0);
    controller.removeItem(0);

    expect(controller.group.items.single.name, 'Fentes');
    expect(controller.group.items.single.duration, const Duration(seconds: 30));
    controller.dispose();
  });
}
