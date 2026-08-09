import '../models/session_step.dart';
import '../models/training.dart';
import '../models/training_item.dart';
import '../validation/business_validation.dart';
import 'training_changes_persistence.dart';
import 'training_storage.dart';

/// Applique une modification de commentaire et restaure l'état précédent
/// lorsque sa persistance échoue.
class SessionCommentUpdater {
  factory SessionCommentUpdater({required TrainingStorage trainingStorage}) =>
      SessionCommentUpdater._(trainingStorage);

  const SessionCommentUpdater._(this._trainingStorage);

  final TrainingStorage _trainingStorage;

  Future<void> update({
    required String? comment,
    required SessionStep currentStep,
    required List<SessionStep> steps,
    required Training training,
    required TrainingChangesPersistence persistence,
    required void Function() onChanged,
  }) async {
    final issue = BusinessValidation.validateComment(comment);
    if (issue != null) throw BusinessValidationException([issue]);

    final sourceItem = currentStep.sourceItem;
    final previousComments = <TrainingItem, String?>{
      sourceItem: sourceItem.comment,
      for (final step in steps)
        if (identical(step.sourceItem, sourceItem))
          step.item: step.item.comment,
    };
    final normalized = BusinessValidation.normalizeComment(comment);
    for (final item in previousComments.keys) {
      item.comment = normalized;
    }
    onChanged();

    if (persistence == TrainingChangesPersistence.memoryOnly) return;
    try {
      await _trainingStorage.addOrUpdateTraining(training);
    } on Object {
      for (final entry in previousComments.entries) {
        entry.key.comment = entry.value;
      }
      onChanged();
      rethrow;
    }
  }
}
