import '../models/exercise_group.dart';

String exerciseGroupTypeLabel(ExerciseGroupType type) {
  return switch (type) {
    ExerciseGroupType.free => "Groupe libre",
  };
}
