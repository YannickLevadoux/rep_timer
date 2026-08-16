import '../models/exercise_group.dart';
import '../models/group_type.dart';
import '../validation/business_validation.dart';

class GroupEditorDraftFactory {
  const GroupEditorDraftFactory._();

  static ExerciseGroup initial(GroupType type, {required String id}) =>
      switch (type) {
        GroupType.tabata => ExerciseGroup.tabata(id: id),
        GroupType.amrap => ExerciseGroup.amrap(id: id),
        GroupType.emom => ExerciseGroup.emom(id: id),
        GroupType.free => ExerciseGroup(id: id, name: '', items: []),
        GroupType.variableRepetitions => ExerciseGroup(
          id: id,
          name: '',
          type: type,
          repetitionSequence: const [BusinessLimits.minimumCount],
          items: [],
        ),
      };

  static ExerciseGroup fromCurrent(GroupType type, ExerciseGroup current) {
    if (!type.isTimed && !current.type.isTimed) {
      final draft = current.copyWith(type: type);
      _initializeSequence(draft, current);
      return draft;
    }
    return switch (type) {
      GroupType.tabata => ExerciseGroup.tabata(id: current.id),
      GroupType.amrap => ExerciseGroup.amrap(id: current.id),
      GroupType.emom => ExerciseGroup.emom(id: current.id),
      GroupType.free => ExerciseGroup(
        id: current.id,
        name: 'Groupe libre',
        items: [],
      ),
      GroupType.variableRepetitions => ExerciseGroup(
        id: current.id,
        name: 'Répétitions variables',
        type: type,
        repetitionSequence: const [BusinessLimits.minimumCount],
        items: [],
      ),
    };
  }

  static void _initializeSequence(ExerciseGroup draft, ExerciseGroup current) {
    if (draft.type != GroupType.variableRepetitions ||
        draft.repetitionSequence.isNotEmpty) {
      return;
    }
    final firstRepetitions = current.items
        .where(
          (item) =>
              BusinessValidation.validateCount(
                item.repetitions,
                field: BusinessField.repetitions,
              ) ==
              null,
        )
        .map((item) => item.repetitions!)
        .firstOrNull;
    final validRounds =
        BusinessValidation.validateCount(
              current.rounds,
              field: BusinessField.groupRounds,
            ) ==
            null
        ? current.rounds
        : BusinessLimits.minimumCount;
    draft.repetitionSequence = List<int>.filled(
      validRounds,
      firstRepetitions ?? BusinessLimits.minimumCount,
    );
  }
}
