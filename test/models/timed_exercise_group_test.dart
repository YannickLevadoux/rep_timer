import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/models/session_step.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/validation/business_validation.dart';

void main() {
  test('les trois types temporisés exposent leurs valeurs par défaut', () {
    final tabata = ExerciseGroup.tabata(id: 'tabata');
    final amrap = ExerciseGroup.amrap(id: 'amrap');
    final emom = ExerciseGroup.emom(id: 'emom');

    expect(tabata.items.map((item) => item.duration), [
      const Duration(seconds: 20),
      const Duration(seconds: 10),
    ]);
    expect(tabata.rounds, 1);
    expect(amrap.items.single.duration, const Duration(minutes: 2));
    expect(amrap.executedRounds, 1);
    expect(emom.rounds, 10);
    expect(emom.items.single.duration, const Duration(minutes: 1));
    for (final group in [tabata, amrap, emom]) {
      expect(BusinessValidation.validateGroup(group), isEmpty);
    }
  });

  test('sérialise et copie profondément les transitions optionnelles', () {
    final original = ExerciseGroup.tabata(id: 'tabata')
      ..rounds = 8
      ..finalRestDuration = const Duration(seconds: 17);
    final decoded = ExerciseGroup.fromJson(original.toJson());
    final copy = original.copyWith();

    expect(decoded.type, GroupType.tabata);
    expect(decoded.finalRestDuration, const Duration(seconds: 17));
    expect(copy.items, isNot(same(original.items)));
    expect(copy.items.first, isNot(same(original.items.first)));
    copy.items.first.name = 'Modifié';
    copy.finalRestDuration = const Duration(seconds: 30);
    expect(original.items.first.name, 'Effort');
    expect(original.finalRestDuration, const Duration(seconds: 17));
    expect(
      copy.copyWith(clearFinalRestDuration: true).finalRestDuration,
      isNull,
    );

    final emom = ExerciseGroup.emom(id: 'emom')
      ..postGroupRestDuration = const Duration(minutes: 1);
    expect(
      ExerciseGroup.fromJson(emom.toJson()).postGroupRestDuration,
      const Duration(minutes: 1),
    );
    expect(
      emom.copyWith(clearPostGroupRestDuration: true).postGroupRestDuration,
      isNull,
    );
  });

  test('applique exactement les bornes Tabata, AMRAP et EMOM', () {
    final tabata = ExerciseGroup.tabata(id: 'tabata');
    for (final rounds in [1, 999]) {
      tabata.rounds = rounds;
      expect(BusinessValidation.validateGroup(tabata), isEmpty);
    }
    tabata.rounds = 1000;
    expect(BusinessValidation.validateGroup(tabata), isNotEmpty);

    final amrap = ExerciseGroup.amrap(id: 'amrap');
    for (final seconds in [60, 3600]) {
      amrap.items.single.duration = Duration(seconds: seconds);
      expect(BusinessValidation.validateGroup(amrap), isEmpty);
    }
    for (final seconds in [59, 3601]) {
      amrap.items.single.duration = Duration(seconds: seconds);
      expect(BusinessValidation.validateGroup(amrap), isNotEmpty);
    }

    final emom = ExerciseGroup.emom(id: 'emom');
    for (final minutes in [1, 60]) {
      emom.rounds = minutes;
      expect(BusinessValidation.validateGroup(emom), isEmpty);
    }
    emom.rounds = 61;
    expect(BusinessValidation.validateGroup(emom), isNotEmpty);
  });

  test('refuse les structures, modes et transitions incompatibles', () {
    final tabata = ExerciseGroup.tabata(id: 'tabata');
    tabata.items = tabata.items.reversed.toList();
    expect(_hasStructureIssue(tabata), isTrue);

    final amrap = ExerciseGroup.amrap(id: 'amrap')..rounds = 2;
    expect(_hasStructureIssue(amrap), isTrue);

    final emom = ExerciseGroup.emom(id: 'emom');
    emom.items.single.duration = const Duration(seconds: 59);
    expect(_hasStructureIssue(emom), isTrue);

    final free = ExerciseGroup(
      id: 'free',
      name: 'Libre',
      items: [
        TrainingItem(type: ItemType.exercise, name: 'Libre', repetitions: 1),
      ],
      postGroupRestDuration: const Duration(seconds: 30),
    );
    expect(_hasStructureIssue(free), isTrue);
  });

  test('développe les pauses de transition sans modifier les groupes', () {
    final tabata = ExerciseGroup.tabata(id: 'tabata')
      ..rounds = 2
      ..finalRestDuration = const Duration(seconds: 17);
    final emom = ExerciseGroup.emom(id: 'emom')
      ..rounds = 2
      ..postGroupRestDuration = const Duration(seconds: 30);
    final training = _training([
      tabata,
      emom,
      ExerciseGroup.amrap(id: 'amrap'),
    ]);

    final steps = buildSessionSteps(training);
    expect(steps, hasLength(8));
    expect(steps[3].item.duration, const Duration(seconds: 17));
    expect(steps[6].item.type, ItemType.rest);
    expect(steps[6].item.duration, const Duration(seconds: 30));
    expect(tabata.items.last.duration, const Duration(seconds: 10));
    expect(emom.items, hasLength(1));
  });
}

bool _hasStructureIssue(ExerciseGroup group) =>
    BusinessValidation.validateGroup(group).any(
      (issue) => issue.code == BusinessValidationCode.invalidGroupStructure,
    );

Training _training(List<ExerciseGroup> groups) => Training(
  id: 'training',
  name: 'Séance',
  groups: groups,
  createdAt: DateTime(2026),
);
