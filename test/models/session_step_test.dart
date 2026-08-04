import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/session_step.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';

void main() {
  group('estimatePlannedDuration', () {
    test('20 s de travail, 10 s de pause et 3 tours donnent 80 s', () {
      final training = _tabata(work: 20, rest: 10, rounds: 3);

      expect(estimatePlannedDuration(training), const Duration(seconds: 80));
    });

    test('un seul tour ne compte que le temps de travail', () {
      final training = _tabata(work: 20, rest: 10, rounds: 1);

      expect(estimatePlannedDuration(training), const Duration(seconds: 20));
    });

    test('les pauses entre deux tours sont conservées', () {
      final training = _tabata(work: 20, rest: 10, rounds: 2);

      expect(buildSessionSteps(training), hasLength(3));
      expect(estimatePlannedDuration(training), const Duration(seconds: 50));
    });

    test('seule la pause finale de toute la séance est retirée', () {
      final training = _training([
        _group('premier', [
          _item(ItemType.exercise, 10),
          _item(ItemType.rest, 5),
        ]),
        _group('second', [
          _item(ItemType.exercise, 20),
          _item(ItemType.rest, 7),
        ]),
      ]);

      final steps = buildSessionSteps(training);
      expect(steps, hasLength(3));
      expect(steps[1].item.type, ItemType.rest);
      expect(estimatePlannedDuration(training), const Duration(seconds: 35));
    });

    test('une séance sans pause finale conserve toutes ses étapes', () {
      final training = _training([
        _group('groupe', [
          _item(ItemType.rest, 5),
          _item(ItemType.exercise, 10),
        ], rounds: 2),
      ]);

      expect(buildSessionSteps(training), hasLength(4));
      expect(estimatePlannedDuration(training), const Duration(seconds: 30));
    });

    test('une séance vide retourne Duration.zero', () {
      expect(estimatePlannedDuration(_training([])), Duration.zero);
    });

    test('une étape sans durée fixe rend la séance non estimable', () {
      final training = _training([
        _group('groupe', [
          TrainingItem(type: ItemType.exercise, name: 'Libre'),
        ]),
      ]);

      expect(estimatePlannedDuration(training), isNull);
    });

    test('le calcul ne modifie ni la séance ni ses éléments', () {
      final training = _tabata(work: 20, rest: 10, rounds: 3);
      final group = training.groups.single;
      final items = List<TrainingItem>.of(group.items);
      final before = training.toJson();

      estimatePlannedDuration(training);

      expect(training.toJson(), equals(before));
      expect(training.groups.single, same(group));
      expect(training.groups.single.items[0], same(items[0]));
      expect(training.groups.single.items[1], same(items[1]));
    });
  });
}

Training _tabata({required int work, required int rest, required int rounds}) {
  return _training([
    _group('tabata', [
      _item(ItemType.exercise, work),
      _item(ItemType.rest, rest),
    ], rounds: rounds),
  ]);
}

Training _training(List<ExerciseGroup> groups) {
  return Training(
    id: 'training',
    name: 'Séance',
    groups: groups,
    createdAt: DateTime(2026),
  );
}

ExerciseGroup _group(String id, List<TrainingItem> items, {int rounds = 1}) {
  return ExerciseGroup(id: id, name: id, rounds: rounds, items: items);
}

TrainingItem _item(ItemType type, int seconds) {
  return TrainingItem(
    type: type,
    name: type.name,
    duration: Duration(seconds: seconds),
  );
}
