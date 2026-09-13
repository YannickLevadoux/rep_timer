import '../models/exercise_group.dart';
import '../models/group_type.dart';
import '../services/group_duration_estimator.dart';
import 'formatters.dart';
import 'repetition_sequence_format.dart';

String formatGroupSummary(
  ExerciseGroup group, {
  required bool hasFollowingGroup,
}) {
  if (group.type == GroupType.variableRepetitions) {
    return '${group.type.label} · '
        '${formatRepetitionSequenceSummary(group.repetitionSequence)}';
  }
  if (group.type == GroupType.free) {
    final label = group.rounds == 1 ? 'répétition' : 'répétitions';
    return '${group.type.label} · ${group.rounds} $label';
  }
  final duration = estimateGroupDuration(
    group,
    hasFollowingGroup: hasFollowingGroup,
  );
  final durationLabel = duration == null
      ? 'Non estimable'
      : formatDuration(duration);
  return switch (group.type) {
    GroupType.tabata => _tabataSummary(group, durationLabel),
    GroupType.amrap => 'AMRAP · Effort · $durationLabel',
    GroupType.emom =>
      'EMOM · ${group.items.isEmpty ? 'Effort' : group.items.first.name} · '
          '$durationLabel',
    _ => throw StateError('Type déjà traité'),
  };
}

String _tabataSummary(ExerciseGroup group, String durationLabel) {
  final rounds = group.tabataConfig?.rounds ?? 1;
  final cycles = group.tabataConfig?.exercises.length ?? group.rounds;
  final cycleLabel = '$cycles ${cycles == 1 ? 'cycle' : 'cycles'}';
  if (rounds == 1) return 'Tabata · $cycleLabel · $durationLabel';
  return 'Tabata · $rounds tours × $cycleLabel · $durationLabel';
}
