import '../models/history_step_entry.dart';
import '../models/amrap_checkpoint_state.dart';
import '../models/amrap_history_data.dart';
import '../models/group_type.dart';
import '../models/session_checkpoint.dart';
import '../models/session_step.dart';
import '../models/training.dart';
import '../models/training_history_entry.dart';
import '../models/training_item.dart';
import 'session_checkpoint_storage.dart';
import 'training_history_storage.dart';

/// Persiste les instantanés d'une séance et construit son entrée
/// d'historique lors de sa clôture.
class SessionCompletionService {
  factory SessionCompletionService({
    required SessionCheckpointStorage checkpointStorage,
    required TrainingHistoryStorage historyStorage,
    DateTime Function()? now,
  }) => SessionCompletionService._(
    checkpointStorage: checkpointStorage,
    historyStorage: historyStorage,
    now: now ?? DateTime.now,
  );

  SessionCompletionService._({
    required this._checkpointStorage,
    required this._historyStorage,
    required this._now,
  });

  final SessionCheckpointStorage _checkpointStorage;
  final TrainingHistoryStorage _historyStorage;
  final DateTime Function() _now;
  bool _historySaved = false;

  Future<void> saveCheckpoint({
    required String trainingId,
    required int currentIndex,
    required List<bool> completed,
    required Duration globalElapsed,
    required Duration stepElapsed,
    required bool paused,
    required List<Duration> stepActualDurations,
    AmrapCheckpointState? amrapState,
  }) {
    return _checkpointStorage.saveCheckpoint(
      SessionCheckpoint(
        trainingId: trainingId,
        currentIndex: currentIndex,
        completed: List<bool>.of(completed),
        globalElapsed: globalElapsed,
        stepElapsed: stepElapsed,
        paused: paused,
        savedAt: _now(),
        stepActualDurations: List<Duration>.of(stepActualDurations),
        amrapState: amrapState,
      ),
    );
  }

  Future<void> completeSession({
    required Training training,
    required List<SessionStep> steps,
    required List<bool> completed,
    required List<Duration> stepActualDurations,
    required Duration totalDuration,
    required TrainingSessionStatus status,
    Map<int, AmrapHistoryData> amrapHistory = const {},
  }) async {
    if (!_historySaved) {
      final now = _now();
      final entry = TrainingHistoryEntry(
        id: now.microsecondsSinceEpoch.toString(),
        trainingId: training.id,
        trainingName: training.name,
        date: now,
        totalDuration: totalDuration,
        status: status,
        steps: <HistoryStepEntry>[
          for (var i = 0; i < steps.length; i++)
            HistoryStepEntry(
              groupId: steps[i].group.id,
              groupName: steps[i].group.name,
              itemType: steps[i].item.type,
              itemName: steps[i].item.name,
              repetitions: steps[i].item.repetitions,
              comment: steps[i].item.comment,
              actualDuration: stepActualDurations[i],
              completed: completed[i],
              emomMinuteIndex:
                  steps[i].group.type == GroupType.emom &&
                      steps[i].item.type == ItemType.exercise
                  ? steps[i].roundIndex
                  : null,
              amrap: amrapHistory[i],
            ),
        ],
      );
      await _historyStorage.addEntry(entry);
      _historySaved = true;
    }

    await _checkpointStorage.clearCheckpoint();
  }

  Future<void> clearCheckpoint() => _checkpointStorage.clearCheckpoint();
}
