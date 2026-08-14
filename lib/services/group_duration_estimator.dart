import '../models/exercise_group.dart';
import '../models/session_step.dart';
import '../models/training.dart';
import '../models/training_item.dart';

Duration? estimateGroupDuration(
  ExerciseGroup group, {
  required bool hasFollowingGroup,
}) {
  final groups = [group];
  if (hasFollowingGroup) {
    groups.add(
      ExerciseGroup(
        id: '__following__',
        name: 'Suite',
        items: [
          TrainingItem(
            type: ItemType.exercise,
            name: 'Suite',
            duration: const Duration(seconds: 1),
          ),
        ],
      ),
    );
  }
  final training = Training(
    id: '__estimate__',
    name: 'Estimation',
    groups: groups,
    createdAt: DateTime(2000),
  );
  var total = Duration.zero;
  for (final step in buildSessionSteps(
    training,
  ).where((step) => step.group.id == group.id)) {
    final duration = step.item.duration;
    if (duration == null) return null;
    total += duration;
  }
  return total;
}
