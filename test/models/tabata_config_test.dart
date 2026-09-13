import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/tabata_config.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/validation/business_validation.dart';

void main() {
  test('expose les valeurs Tabata par défaut', () {
    final group = ExerciseGroup.tabata(id: 'tabata');
    final config = group.tabataConfig!;

    expect(config.rounds, 1);
    expect(config.exercises, hasLength(1));
    expect(config.effortDuration, const Duration(seconds: 20));
    expect(config.restDuration, const Duration(seconds: 10));
    expect(config.finalRestDuration, isNull);
    expect(BusinessValidation.validateGroup(group), isEmpty);
  });

  test('valide les bornes exactes des tours et cycles', () {
    for (final rounds in [1, 99]) {
      final group = _group(rounds: rounds, cycles: 1);
      expect(BusinessValidation.validateGroup(group), isEmpty);
    }
    for (final rounds in [0, 100]) {
      expect(
        BusinessValidation.validateGroup(_group(rounds: rounds)),
        isNotEmpty,
      );
    }
    for (final cycles in [1, 999]) {
      expect(BusinessValidation.validateGroup(_group(cycles: cycles)), isEmpty);
    }
    for (final cycles in [0, 1000]) {
      expect(
        BusinessValidation.validateGroup(_group(cycles: cycles)),
        isNotEmpty,
      );
    }
  });

  test('initialise et conserve la pause de fin de tour', () {
    final config = TabataConfig.defaults();

    config.rounds = 2;
    expect(config.finalRestDuration, config.restDuration);
    config.finalRestDuration = const Duration(seconds: 17);
    config.rounds = 1;
    expect(config.finalRestDuration, const Duration(seconds: 17));
    config.rounds = 2;
    expect(config.finalRestDuration, const Duration(seconds: 17));
  });

  test('refuse pause manquante, durées divergentes et exercice invalide', () {
    final missingRest = _group(rounds: 2, finalRest: null);
    expect(BusinessValidation.validateGroup(missingRest), isNotEmpty);

    final divergent = _group(cycles: 2);
    divergent.tabataConfig!.exercises.last.duration = const Duration(
      seconds: 21,
    );
    expect(_hasStructureIssue(divergent), isTrue);

    final invalid = _group();
    invalid.tabataConfig!.exercises.single.name = '  ';
    expect(
      BusinessValidation.validateGroup(
        invalid,
      ).any((issue) => issue.field == BusinessField.exerciseName),
      isTrue,
    );
  });

  test('copie et normalise profondément tous les exercices', () {
    final original = _group(cycles: 2);
    original.tabataConfig!.exercises[1]
      ..name = '  Burpee  '
      ..comment = '  Ligne\r\nDeux  '
      ..iconName = 'directions_run';

    final copy = original.copyWith();
    final normalized = BusinessValidation.normalizedTrainingCopy(
      _training([original]),
    ).groups.single;

    expect(
      copy.tabataConfig!.exercises,
      isNot(same(original.tabataConfig!.exercises)),
    );
    expect(
      copy.tabataConfig!.exercises[1],
      isNot(same(original.tabataConfig!.exercises[1])),
    );
    copy.tabataConfig!.exercises[1].name = 'Modifié';
    expect(original.tabataConfig!.exercises[1].name, '  Burpee  ');
    expect(normalized.tabataConfig!.exercises[1].name, 'Burpee');
    expect(normalized.tabataConfig!.exercises[1].comment, 'Ligne\nDeux');
    expect(normalized.tabataConfig!.exercises[1].iconName, 'directions_run');
  });

  test('sérialise un puis plusieurs tours et cycles sans ambiguïté', () {
    for (final group in [_group(), _group(rounds: 3, cycles: 4)]) {
      final json = group.toJson();
      final decoded = ExerciseGroup.fromJson(json);

      expect(json, isNot(contains('rounds')));
      expect(json, isNot(contains('items')));
      expect(decoded.toJson(), json);
      expect(decoded.tabataConfig!.rounds, group.tabataConfig!.rounds);
      expect(
        decoded.tabataConfig!.exercises.length,
        group.tabataConfig!.exercises.length,
      );
    }
  });

  test('convertit les Tabata historiques de 1, plusieurs et 999 cycles', () {
    for (final cycles in [1, 3, 999]) {
      final converted = ExerciseGroup.fromJson(_legacyJson(cycles));
      final config = converted.tabataConfig!;

      expect(config.rounds, 1);
      expect(config.exercises, hasLength(cycles));
      expect(config.exercises.every((item) => item.name == 'Squat'), isTrue);
      expect(config.exercises.every((item) => item.iconName == 'star'), isTrue);
      expect(config.exercises.every((item) => item.comment == 'Lent'), isTrue);
      expect(config.effortDuration, const Duration(seconds: 25));
      expect(config.restDuration, const Duration(seconds: 11));
      expect(config.finalRestDuration, const Duration(seconds: 19));
      expect(
        ExerciseGroup.fromJson(converted.toJson()).toJson(),
        converted.toJson(),
      );
    }
  });

  test('borne 10 000 acceptée et 10 001 refusée sans développement', () {
    final tabata = _group(rounds: 50, cycles: 100);
    final accepted = _training([_free(items: 1), tabata]);
    final refused = _training([_free(items: 2), tabata]);

    expect(BusinessValidation.sessionStepUpperBound(accepted), 10000);
    expect(BusinessValidation.validateSessionStepLimit(accepted), isNull);
    expect(BusinessValidation.sessionStepUpperBound(refused), 10001);
    expect(BusinessValidation.validateSessionStepLimit(refused), isNotNull);
    expect(
      BusinessValidation.sessionStepUpperBound(
        _training([_group(rounds: 99, cycles: 999)]),
      ),
      10001,
    );
  });
}

ExerciseGroup _group({
  int rounds = 1,
  int cycles = 1,
  Duration? finalRest = const Duration(seconds: 10),
}) => ExerciseGroup.withTabataConfig(
  id: 'tabata',
  name: 'Tabata',
  config: TabataConfig(
    rounds: rounds,
    exercises: List.generate(
      cycles,
      (index) => TrainingItem(
        type: ItemType.exercise,
        name: 'Effort ${index + 1}',
        duration: const Duration(seconds: 20),
      ),
    ),
    restDuration: const Duration(seconds: 10),
    finalRestDuration: rounds > 1 ? finalRest : null,
  ),
);

Map<String, dynamic> _legacyJson(int cycles) => {
  'id': 'legacy',
  'name': 'Ancien',
  'type': 'tabata',
  'rounds': cycles,
  'repetitionSequence': <int>[],
  'finalRestDurationSeconds': 19,
  'postGroupRestDurationSeconds': null,
  'items': [
    TrainingItem(
      type: ItemType.exercise,
      name: 'Squat',
      duration: const Duration(seconds: 25),
      comment: 'Lent',
      iconName: 'star',
    ).toJson(),
    TrainingItem(
      type: ItemType.rest,
      name: 'Pause',
      duration: const Duration(seconds: 11),
    ).toJson(),
  ],
};

ExerciseGroup _free({required int items}) => ExerciseGroup(
  id: 'free',
  name: 'Libre',
  items: List.generate(
    items,
    (index) => TrainingItem(
      type: ItemType.exercise,
      name: 'Exercice $index',
      repetitions: 1,
    ),
  ),
);

Training _training(List<ExerciseGroup> groups) => Training(
  id: 'training',
  name: 'Séance',
  groups: groups,
  createdAt: DateTime(2026),
);

bool _hasStructureIssue(ExerciseGroup group) =>
    BusinessValidation.validateGroup(group).any(
      (issue) => issue.code == BusinessValidationCode.invalidGroupStructure,
    );
