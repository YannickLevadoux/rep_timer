import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/controllers/group_editor_controller.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/models/training_item.dart';

void main() {
  test("ExerciseGroup.copyWith renvoie une copie profonde : muter la copie "
      "ne doit jamais atteindre l'original tant que la sauvegarde n'a pas "
      "été explicitement déclenchée (clic sur \"Enregistrer\")", () {
    final original = ExerciseGroup(
      id: 'group-1',
      name: 'Circuit',
      rounds: 2,
      items: [
        TrainingItem(type: ItemType.exercise, name: 'Squats', repetitions: 10),
        TrainingItem(
          type: ItemType.rest,
          name: 'Pause',
          duration: const Duration(seconds: 30),
        ),
      ],
    );

    final copy = original.copyWith();

    // Même id par défaut : une édition d'un groupe existant doit
    // remplacer le même groupe une fois enregistrée, pas en créer un
    // nouveau.
    expect(copy.id, original.id);
    expect(copy.name, original.name);
    expect(copy.rounds, original.rounds);

    // Les items de la copie ne sont jamais les mêmes instances que
    // ceux de l'original (voir TrainingItem.copyWith appelé en
    // interne) : sans ça, l'édition en cours modifierait discrètement
    // l'original avant tout clic sur "Enregistrer".
    expect(copy.items[0], isNot(same(original.items[0])));
    expect(copy.items[1], isNot(same(original.items[1])));
    expect(copy.items, isNot(same(original.items)));

    // Simule une édition en cours : rien de tout ceci ne doit se
    // répercuter sur l'original avant sauvegarde explicite.
    copy.name = 'Modifié';
    copy.rounds = 5;
    copy.items[0].name = 'Fentes';
    copy.items[0].repetitions = 99;
    copy.items.add(TrainingItem(type: ItemType.exercise, name: 'Ajouté'));
    copy.items.removeAt(1);

    expect(original.name, 'Circuit');
    expect(original.rounds, 2);
    expect(original.items.length, 2);
    expect(original.items[0].name, 'Squats');
    expect(original.items[0].repetitions, 10);
    expect(original.items[1].name, 'Pause');

    // Cas de l'import (training_import_service) : un nouvel id est
    // fourni, mais la copie profonde des items reste garantie.
    final imported = original.copyWith(id: 'new-id');
    expect(imported.id, 'new-id');
    expect(imported.items[0], isNot(same(original.items[0])));

    imported.items[0].name = 'Touché après import';
    expect(original.items[0].name, 'Squats');
  });

  test("GroupType.fromName résout un nom connu et replie sur GroupType.free "
      "pour toute valeur absente ou inconnue, sans jamais planter — c'est le "
      "garde-fou contre un futur type inconnu reçu via un import", () {
    expect(GroupType.fromName('free'), GroupType.free);
    expect(
      GroupType.fromName('variableRepetitions'),
      GroupType.variableRepetitions,
    );
    expect(GroupType.fromName(null), GroupType.free);
    expect(GroupType.fromName(''), GroupType.free);

    // Type hypothétique introduit par une version future de l'app et
    // exporté vers une version antérieure qui ne le connaît pas
    // encore (ou donnée corrompue) : ne doit jamais lever d'exception,
    // seulement replier sur .free.
    expect(GroupType.fromName('circuit'), GroupType.free);
    expect(GroupType.fromName('unknown_type_from_the_future'), GroupType.free);
  });

  test('la suite est sérialisée, désérialisée et copiée profondément', () {
    final original = ExerciseGroup(
      id: 'variable',
      name: 'Pyramide',
      type: GroupType.variableRepetitions,
      rounds: 7,
      repetitionSequence: [10, 12, 15],
      items: [],
    );

    final decoded = ExerciseGroup.fromJson(original.toJson());
    final copy = original.copyWith();

    expect(decoded.type, GroupType.variableRepetitions);
    expect(decoded.rounds, 7);
    expect(decoded.repetitionSequence, [10, 12, 15]);
    expect(decoded.executedRounds, 3);
    expect(copy.repetitionSequence, [10, 12, 15]);
    expect(copy.repetitionSequence, isNot(same(original.repetitionSequence)));

    copy.repetitionSequence[0] = 99;
    expect(original.repetitionSequence, [10, 12, 15]);
  });

  test("une ancienne donnée sans suite reste un groupe libre lisible", () {
    final decoded = ExerciseGroup.fromJson({
      'id': 'legacy',
      'name': 'Ancien',
      'rounds': 2,
      'items': <dynamic>[],
    });

    expect(decoded.type, GroupType.free);
    expect(decoded.repetitionSequence, isEmpty);
    expect(decoded.executedRounds, 2);
  });

  test('le changement de type aller-retour ne perd aucune donnée', () {
    final original = ExerciseGroup(
      id: 'group',
      name: 'Circuit',
      rounds: 3,
      items: [
        TrainingItem(type: ItemType.exercise, name: 'Squats', repetitions: 7),
      ],
    );
    final controller = GroupEditorController(original);
    addTearDown(controller.dispose);

    controller.setType(GroupType.variableRepetitions);
    expect(controller.group.rounds, 3);
    expect(controller.group.items.single.repetitions, 7);
    expect(controller.group.repetitionSequence, [7, 7, 7]);

    controller.setRepetitionSequence([10, 12, 15]);
    controller.setType(GroupType.free);
    expect(controller.group.rounds, 3);
    expect(controller.group.items.single.repetitions, 7);
    expect(controller.group.repetitionSequence, [10, 12, 15]);

    controller.setType(GroupType.variableRepetitions);
    expect(controller.group.repetitionSequence, [10, 12, 15]);
    expect(original.type, GroupType.free);
    expect(original.repetitionSequence, isEmpty);
  });
}
