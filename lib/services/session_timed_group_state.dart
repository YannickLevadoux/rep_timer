import '../models/amrap_checkpoint_state.dart';
import '../models/amrap_history_data.dart';
import '../models/group_type.dart';
import '../models/session_checkpoint.dart';
import '../models/session_step.dart';
import 'amrap_execution_state.dart';

/// Coordonne les états temporisés purs avec les indices du plan de séance.
class SessionTimedGroupState {
  SessionTimedGroupState({
    required List<SessionStep> steps,
    required int currentIndex,
    SessionCheckpoint? checkpoint,
  }) {
    for (var index = 0; index < steps.length; index++) {
      final step = steps[index];
      if (step.group.type != GroupType.amrap) continue;
      _amrapStates[index] = AmrapExecutionState(step.item.duration!);
    }
    final restored = checkpoint?.amrapState;
    if (restored != null && _amrapStates.containsKey(currentIndex)) {
      final duration = steps[currentIndex].item.duration;
      if (duration == restored.configuredDuration) {
        _amrapStates[currentIndex] = AmrapExecutionState.fromCheckpoint(
          restored,
        );
      }
    }
  }

  final Map<int, AmrapExecutionState> _amrapStates = {};

  bool isAmrap(int index) => _amrapStates.containsKey(index);

  AmrapExecutionSnapshot? snapshot({
    required int index,
    required Duration stepElapsed,
    required bool paused,
  }) {
    final state = _amrapStates[index];
    if (state == null) return null;
    state.synchronize(stepElapsed);
    return state.snapshot(paused: paused);
  }

  bool recordLap({
    required int index,
    required Duration stepElapsed,
    required bool paused,
  }) => _amrapStates[index]?.recordLap(stepElapsed, paused: paused) ?? false;

  bool undoLastLap({required int index, required Duration stepElapsed}) =>
      _amrapStates[index]?.undoLastLap(stepElapsed) ?? false;

  bool requiresRestart(int index) =>
      _amrapStates[index]?.requiresRestart ?? false;

  void leaveCurrent({required int index, required Duration stepElapsed}) {
    _amrapStates[index]?.markIncomplete(stepElapsed);
  }

  void restart(int index) => _amrapStates[index]?.restart();

  void completeCurrent({required int index, required Duration stepElapsed}) =>
      _amrapStates[index]?.markCompleted(stepElapsed);

  AmrapCheckpointState? checkpointFor({
    required int index,
    required Duration stepElapsed,
  }) {
    final state = _amrapStates[index];
    if (state == null) return null;
    state.synchronize(stepElapsed);
    return state.toCheckpoint();
  }

  Map<int, AmrapHistoryData> historyData(List<bool> completed) => {
    for (final entry in _amrapStates.entries)
      entry.key: entry.value.toHistory(stepCompleted: completed[entry.key]),
  };
}
