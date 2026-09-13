import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/controllers/group_editor_controller.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/models/training_item.dart';

void main() {
  test('un ajout attend un type et refuse une soumission sans sélection', () {
    final controller = GroupEditorController(
      ExerciseGroup(id: 'group', name: '', items: []),
      requiresInitialTypeSelection: true,
    );

    expect(controller.selectedType, isNull);
    expect(controller.hasSelectedType, isFalse);
    expect(controller.hasUnsavedChanges, isFalse);
    expect(controller.saveIfSelected(), isNull);
    expect(() => controller.group, throwsStateError);
    controller.dispose();
  });

  test('la première sélection crée les cinq modèles par défaut', () {
    for (final type in GroupType.values) {
      final controller = GroupEditorController(
        ExerciseGroup(id: 'group', name: '', items: []),
        requiresInitialTypeSelection: true,
      );

      expect(controller.requiresReplacementConfirmation(type), isFalse);
      controller.switchType(type);

      expect(controller.selectedType, type);
      expect(controller.hasUnsavedChanges, isTrue);
      switch (type) {
        case GroupType.free:
          expect(controller.group.name, 'Libre');
          expect(controller.group.items, isEmpty);
          expect(controller.group.rounds, 1);
        case GroupType.variableRepetitions:
          expect(controller.group.name, 'Variables');
          expect(controller.group.items, isEmpty);
          expect(controller.group.repetitionSequence, [1]);
        case GroupType.tabata:
          expect(controller.group.name, 'Tabata');
          expect(controller.group.rounds, 1);
          expect(controller.group.items.map((item) => item.duration), [
            const Duration(seconds: 20),
            const Duration(seconds: 10),
          ]);
        case GroupType.amrap:
          expect(controller.group.name, 'AMRAP');
          expect(
            controller.group.items.single.duration,
            const Duration(minutes: 2),
          );
        case GroupType.emom:
          expect(controller.group.name, 'EMOM');
          expect(controller.group.rounds, 10);
          expect(
            controller.group.items.single.duration,
            const Duration(minutes: 1),
          );
      }
      controller.dispose();
    }
  });

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
    expect(controller.group.name, 'Libre');
    controller.switchType(GroupType.variableRepetitions);
    expect(controller.group.repetitionSequence, [1]);
    expect(controller.group.name, 'Libre');
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

  test('synchronise les cycles Tabata avec leur liste unique', () {
    final controller = GroupEditorController(ExerciseGroup.tabata(id: 'g'));

    expect(controller.tabataCycleCount, 1);
    expect(controller.addTabataExercise(), isTrue);
    expect(controller.group.rounds, 2);
    expect(controller.group.tabataConfig!.exercises.map((item) => item.name), [
      'Effort',
      'Effort 2',
    ]);
    expect(
      controller.group.items.first,
      same(controller.group.tabataConfig!.exercises.first),
    );

    expect(controller.removeLastTabataExercise(), isTrue);
    expect(controller.tabataCycleCount, 1);
    expect(controller.removeLastTabataExercise(), isFalse);
    controller.dispose();
  });

  test('préremplit le brouillon et sécurise un ajout depuis le compteur', () {
    final controller = GroupEditorController(ExerciseGroup.tabata(id: 'g'));
    controller.configureNewTabataExerciseName(prefill: true);
    expect(controller.group.tabataConfig!.exercises.single.name, 'Effort 1');

    controller.addTabataExercise();
    expect(controller.group.tabataConfig!.exercises.last.name, 'Effort 2');
    expect(controller.lastTabataExerciseIsCustomized, isFalse);
    controller.group.tabataConfig!.exercises.last.name = 'Burpees';
    expect(controller.lastTabataExerciseIsCustomized, isTrue);
    controller.group.tabataConfig!.exercises.last
      ..name = ''
      ..iconName = 'rowing';
    expect(controller.lastTabataExerciseIsCustomized, isTrue);
    controller.dispose();
  });

  test('refuse les bornes Tabata invalides dans le contrôleur', () {
    final group = ExerciseGroup.tabata(id: 'g')..rounds = 999;
    final controller = GroupEditorController(group);

    expect(controller.addTabataExercise(), isFalse);
    controller.setTabataRounds(0);
    expect(controller.tabataRounds, 1);
    controller.setTabataRounds(100);
    expect(controller.tabataRounds, 1);
    expect(
      controller.replaceTabataExercises(
        List.generate(
          1000,
          (index) => TrainingItem(
            type: ItemType.exercise,
            name: 'Effort ${index + 1}',
            duration: const Duration(seconds: 20),
          ),
        ),
      ),
      isFalse,
    );
    expect(controller.tabataCycleCount, 999);
    controller.dispose();
  });

  test('applique atomiquement une liste Tabata valide seulement', () {
    final controller = GroupEditorController(ExerciseGroup.tabata(id: 'g'));
    final valid = [
      TrainingItem(
        type: ItemType.exercise,
        name: 'Squats',
        duration: const Duration(seconds: 20),
        comment: 'Lentement',
        iconName: 'rowing',
      ),
      TrainingItem(
        type: ItemType.exercise,
        name: 'Burpees',
        duration: const Duration(seconds: 20),
      ),
    ];

    expect(controller.replaceTabataExercises(valid), isTrue);
    expect(controller.tabataCycleCount, 2);
    expect(controller.group.tabataConfig!.exercises.first.comment, 'Lentement');
    expect(controller.group.tabataConfig!.exercises.first.iconName, 'rowing');
    expect(
      controller.replaceTabataExercises([
        TrainingItem(
          type: ItemType.exercise,
          name: '',
          duration: const Duration(seconds: 20),
        ),
      ]),
      isFalse,
    );
    expect(controller.group.tabataConfig!.exercises.map((item) => item.name), [
      'Squats',
      'Burpees',
    ]);
    controller.dispose();
  });

  test('gère les tours et la pause de fin sans perte', () {
    final controller = GroupEditorController(ExerciseGroup.tabata(id: 'g'));
    controller.setRequiredRestDuration(const Duration(seconds: 17));
    controller.setTabataRounds(2);
    expect(controller.tabataRounds, 2);
    expect(controller.group.finalRestDuration, const Duration(seconds: 17));
    expect(controller.canDeleteTabataFinalRest, isFalse);

    controller.setFinalRestEnabled(false);
    expect(controller.group.finalRestDuration, const Duration(seconds: 17));
    controller.setFinalRestDuration(const Duration(seconds: 23));
    controller.setTabataRounds(1);
    expect(controller.group.finalRestDuration, const Duration(seconds: 23));
    expect(controller.canDeleteTabataFinalRest, isTrue);
    controller.setFinalRestEnabled(false);
    expect(controller.group.finalRestDuration, isNull);
    controller.dispose();
  });

  test('modifie la durée commune de tous les efforts Tabata', () {
    final controller = GroupEditorController(ExerciseGroup.tabata(id: 'g'));
    controller.addTabataExercise();
    controller.setEffortDuration(const Duration(seconds: 45));

    expect(
      controller.group.tabataConfig!.exercises.map((item) => item.duration),
      everyElement(const Duration(seconds: 45)),
    );
    controller.dispose();
  });
}
