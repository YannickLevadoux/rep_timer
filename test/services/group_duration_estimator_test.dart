import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/group_duration_estimator.dart';
import 'package:rep_timer/utils/group_summary.dart';

void main() {
  test('Tabata inclut la dernière pause seulement si un groupe suit', () {
    final group = ExerciseGroup.tabata(id: 'tabata')
      ..rounds = 8
      ..finalRestDuration = const Duration(seconds: 17);

    expect(
      estimateGroupDuration(group, hasFollowingGroup: false),
      const Duration(minutes: 3, seconds: 50),
    );
    expect(
      estimateGroupDuration(group, hasFollowingGroup: true),
      const Duration(minutes: 4, seconds: 7),
    );
    expect(
      formatGroupSummary(group, hasFollowingGroup: false),
      'Tabata · 8 cycles · 03:50',
    );
  });

  test(
    'AMRAP et EMOM incluent leur récupération seulement avant une suite',
    () {
      final amrap = ExerciseGroup.amrap(id: 'amrap')
        ..postGroupRestDuration = const Duration(minutes: 1);
      final emom = ExerciseGroup.emom(id: 'emom')
        ..postGroupRestDuration = const Duration(seconds: 30);

      expect(
        estimateGroupDuration(amrap, hasFollowingGroup: false),
        const Duration(minutes: 2),
      );
      expect(
        estimateGroupDuration(amrap, hasFollowingGroup: true),
        const Duration(minutes: 3),
      );
      expect(
        estimateGroupDuration(emom, hasFollowingGroup: false),
        const Duration(minutes: 10),
      );
      expect(
        estimateGroupDuration(emom, hasFollowingGroup: true),
        const Duration(minutes: 10, seconds: 30),
      );
      expect(
        formatGroupSummary(amrap, hasFollowingGroup: false),
        'AMRAP · Effort · 02:00',
      );
      expect(
        formatGroupSummary(emom, hasFollowingGroup: false),
        'EMOM · Effort · 10:00',
      );
    },
  );

  test('résume Libre, Variables et une durée non estimable', () {
    final free = ExerciseGroup(id: 'free', name: 'Libre', rounds: 2, items: []);
    final variable = ExerciseGroup(
      id: 'variable',
      name: 'Pyramide',
      type: GroupType.variableRepetitions,
      repetitionSequence: [8, 10],
      items: [],
    );
    final invalidTabata = ExerciseGroup(
      id: 'invalid',
      name: 'Tabata',
      type: GroupType.tabata,
      items: [
        TrainingItem(type: ItemType.exercise, name: 'Effort', repetitions: 1),
      ],
    );

    expect(
      formatGroupSummary(free, hasFollowingGroup: false),
      'Groupe libre · 2 répétitions',
    );
    expect(
      formatGroupSummary(variable, hasFollowingGroup: false),
      'Groupe à répétitions variables · 2 tours · 8 → 10',
    );
    expect(
      formatGroupSummary(invalidTabata, hasFollowingGroup: false),
      'Tabata · 1 cycle · Non estimable',
    );
  });
}
