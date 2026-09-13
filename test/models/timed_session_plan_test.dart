import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/session_step.dart';
import 'package:rep_timer/models/tabata_config.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/validation/business_validation.dart';

void main() {
  test('Tabata développe un et plusieurs cycles sans pause finale', () {
    final single = ExerciseGroup.tabata(id: 'single');
    final multiple = ExerciseGroup.tabata(id: 'multiple')..rounds = 3;

    expect(buildSessionSteps(_training([single])), hasLength(1));
    final steps = buildSessionSteps(_training([multiple]));
    expect(steps, hasLength(5));
    expect(steps.map((step) => step.item.type), [
      ItemType.exercise,
      ItemType.rest,
      ItemType.exercise,
      ItemType.rest,
      ItemType.exercise,
    ]);
    expect(
      estimatePlannedDuration(_training([multiple])),
      const Duration(seconds: 80),
    );
  });

  test('Tabata remplace seulement la dernière pause lorsqu’un groupe suit', () {
    final tabata = ExerciseGroup.tabata(id: 'tabata')
      ..rounds = 2
      ..finalRestDuration = const Duration(seconds: 17);
    final sourceRest = tabata.items.last;
    final steps = buildSessionSteps(_training([tabata, _followingGroup()]));

    expect(steps.take(4).map((step) => step.item.duration), [
      const Duration(seconds: 20),
      const Duration(seconds: 10),
      const Duration(seconds: 20),
      const Duration(seconds: 17),
    ]);
    expect(steps[3].sourceItem, same(sourceRest));
    expect(steps[3].item, isNot(same(sourceRest)));
    expect(sourceRest.duration, const Duration(seconds: 10));
  });

  test('Tabata développe exactement les plans 1×1, 1×4 et 2×1', () {
    expect(
      buildSessionSteps(
        _training([
          _tabata(1, ['A']),
        ]),
      ),
      hasLength(1),
    );
    expect(
      buildSessionSteps(
        _training([
          _tabata(1, ['A', 'B', 'C', 'D']),
        ]),
      ).map((step) => step.item.type),
      [
        ItemType.exercise,
        ItemType.rest,
        ItemType.exercise,
        ItemType.rest,
        ItemType.exercise,
        ItemType.rest,
        ItemType.exercise,
      ],
    );
    final twoByOne = buildSessionSteps(
      _training([
        _tabata(2, ['A']),
      ]),
    );
    expect(twoByOne.map((step) => step.item.name), ['A', 'Pause', 'A']);
    expect(twoByOne[1].item.duration, const Duration(seconds: 17));
  });

  test('Tabata 2×4 conserve ordre, identité, pauses et métadonnées', () {
    final group = _tabata(2, ['A', 'B', 'C', 'D']);
    final config = group.tabataConfig!;
    final before = group.toJson();
    final steps = buildSessionSteps(_training([group]));

    expect(steps, hasLength(15));
    expect(
      steps
          .where((step) => step.item.type == ItemType.exercise)
          .map((step) => step.item.name),
      ['A', 'B', 'C', 'D', 'A', 'B', 'C', 'D'],
    );
    expect(
      steps.indexed.every(
        (entry) =>
            entry.$1 == 0 ||
            entry.$2.item.type != steps[entry.$1 - 1].item.type ||
            entry.$2.item.type == ItemType.exercise,
      ),
      isTrue,
    );
    expect(steps[7].item.duration, const Duration(seconds: 17));
    expect(steps[7].sourceItem, same(config.legacyRestItem));
    expect(steps[7].item, isNot(same(config.legacyRestItem)));
    expect(steps.last.item, same(config.exercises.last));
    expect(group.toJson(), before);

    final lastEffort = steps.last;
    expect(lastEffort.roundIndex, 4);
    expect(lastEffort.totalRounds, 4);
    expect(lastEffort.tabataRoundIndex, 2);
    expect(lastEffort.tabataRoundTotal, 2);
    expect(lastEffort.tabataCycleIndex, 4);
    expect(lastEffort.tabataCycleTotal, 4);
    expect(
      steps.every(
        (step) =>
            step.tabataRoundIndex != null && step.tabataCycleIndex != null,
      ),
      isTrue,
    );
  });

  test('Tabata 2×4 ajoute la pause finale seulement avant une suite', () {
    final group = _tabata(2, ['A', 'B', 'C', 'D']);
    final alone = buildSessionSteps(_training([group]));
    final followed = buildSessionSteps(
      _training([group, _followingGroup()]),
    ).where((step) => step.group.id == group.id);

    expect(alone, hasLength(15));
    expect(followed, hasLength(16));
    expect(followed.last.item.type, ItemType.rest);
    expect(followed.last.item.duration, const Duration(seconds: 17));
    expect(
      alone.fold(Duration.zero, (sum, step) => sum + step.item.duration!),
      const Duration(minutes: 3, seconds: 57),
    );
    expect(
      followed.fold(Duration.zero, (sum, step) => sum + step.item.duration!),
      const Duration(minutes: 4, seconds: 14),
    );
  });

  test(
    'EMOM développe 1, 10 et 60 minutes puis la récupération conditionnelle',
    () {
      for (final minutes in [1, 10, 60]) {
        final emom = ExerciseGroup.emom(id: 'emom')..rounds = minutes;
        final steps = buildSessionSteps(_training([emom]));
        expect(steps, hasLength(minutes));
        expect(
          steps.every(
            (step) => step.item.duration == const Duration(minutes: 1),
          ),
          isTrue,
        );
        expect(
          estimatePlannedDuration(_training([emom])),
          Duration(minutes: minutes),
        );
      }

      final emom = ExerciseGroup.emom(id: 'rested')
        ..rounds = 1
        ..postGroupRestDuration = const Duration(seconds: 30);
      expect(buildSessionSteps(_training([emom])), hasLength(1));
      final followed = buildSessionSteps(_training([emom, _followingGroup()]));
      expect(followed[1].item.type, ItemType.rest);
      expect(followed[1].item.duration, const Duration(seconds: 30));
    },
  );

  test('AMRAP reste une étape unique avec récupération conditionnelle', () {
    final amrap = ExerciseGroup.amrap(id: 'amrap')
      ..postGroupRestDuration = const Duration(minutes: 1);

    final alone = buildSessionSteps(_training([amrap]));
    expect(alone, hasLength(1));
    expect(alone.single.item.type, ItemType.exercise);
    expect(alone.single.totalRounds, 1);

    final followed = buildSessionSteps(_training([amrap, _followingGroup()]));
    expect(followed.take(2).map((step) => step.item.type), [
      ItemType.exercise,
      ItemType.rest,
    ]);
    expect(followed[1].item.duration, const Duration(minutes: 1));
  });

  test('accepte exactement 10 000 étapes réellement développées', () {
    final prefix = ExerciseGroup(
      id: 'prefix',
      name: 'Préfixe',
      items: List.generate(
        8003,
        (index) => TrainingItem(
          type: ItemType.exercise,
          name: 'Exercice $index',
          repetitions: 1,
        ),
      ),
    );
    final tabata = ExerciseGroup.tabata(id: 'tabata')..rounds = 999;
    final training = _training([prefix, tabata]);

    expect(BusinessValidation.validateSessionStepLimit(training), isNull);
    expect(buildSessionSteps(training), hasLength(10000));

    prefix.items.add(
      TrainingItem(type: ItemType.exercise, name: 'En trop', repetitions: 1),
    );
    expect(
      BusinessValidation.validateSessionStepLimit(training)?.code,
      BusinessValidationCode.tooManySteps,
    );
  });
}

ExerciseGroup _tabata(int rounds, List<String> names) =>
    ExerciseGroup.withTabataConfig(
      id: 'tabata-$rounds-${names.length}',
      name: 'Tabata',
      config: TabataConfig(
        rounds: rounds,
        exercises: [
          for (final name in names)
            TrainingItem(
              type: ItemType.exercise,
              name: name,
              duration: const Duration(seconds: 20),
            ),
        ],
        restDuration: const Duration(seconds: 10),
        finalRestDuration: rounds > 1 ? const Duration(seconds: 17) : null,
      ),
    );

ExerciseGroup _followingGroup() => ExerciseGroup(
  id: 'following',
  name: 'Suite',
  items: [TrainingItem(type: ItemType.exercise, name: 'Suite', repetitions: 1)],
);

Training _training(List<ExerciseGroup> groups) => Training(
  id: 'training',
  name: 'Séance',
  groups: groups,
  createdAt: DateTime(2026),
);
