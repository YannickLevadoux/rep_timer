import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/session_step.dart';
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
