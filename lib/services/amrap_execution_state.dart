import '../models/amrap_checkpoint_state.dart';
import '../models/amrap_history_data.dart';
import '../validation/validation_contract.dart';

enum AmrapAttemptStatus { notStarted, running, incomplete, completed }

/// État métier pur d'une occurrence AMRAP. Toutes les durées sont ramenées à
/// des secondes entières afin de produire des checkpoints déterministes.
class AmrapExecutionState {
  AmrapExecutionState(Duration configuredDuration)
    : _configuredDuration = configuredDuration,
      _completedLaps = [];

  AmrapExecutionState.fromCheckpoint(AmrapCheckpointState checkpoint)
    : _configuredDuration = checkpoint.configuredDuration,
      _activeElapsed = checkpoint.activeElapsed,
      _completedLaps = List.of(checkpoint.completedLapDurations),
      _currentLapDuration = checkpoint.currentLapDuration,
      _buttonDelayRemaining = checkpoint.buttonDelayRemaining,
      _lastClockElapsed = checkpoint.activeElapsed,
      _status = checkpoint.completed
          ? AmrapAttemptStatus.completed
          : checkpoint.incomplete
          ? AmrapAttemptStatus.incomplete
          : checkpoint.activeElapsed > Duration.zero
          ? AmrapAttemptStatus.running
          : AmrapAttemptStatus.notStarted;

  final Duration _configuredDuration;
  Duration _activeElapsed = Duration.zero;
  final List<Duration> _completedLaps;
  Duration _currentLapDuration = Duration.zero;
  Duration _buttonDelayRemaining = Duration.zero;
  Duration _lastClockElapsed = Duration.zero;
  AmrapAttemptStatus _status = AmrapAttemptStatus.notStarted;

  Duration get configuredDuration => _configuredDuration;
  Duration get activeElapsed => _activeElapsed;
  Duration get activeRemaining => _configuredDuration - _activeElapsed;
  Duration get currentLapDuration => _currentLapDuration;
  Duration get buttonDelayRemaining => _buttonDelayRemaining;
  List<Duration> get completedLapDurations => List.unmodifiable(_completedLaps);
  int get completedLapCount => _completedLaps.length;
  bool get limitReached => completedLapCount >= BusinessLimits.maximumAmrapLaps;
  bool get completed => _status == AmrapAttemptStatus.completed;
  bool get started => _activeElapsed > Duration.zero || completed;
  bool get requiresRestart =>
      started || _status == AmrapAttemptStatus.incomplete;
  bool get canUndoLastLap =>
      _status == AmrapAttemptStatus.running && _completedLaps.isNotEmpty;

  void synchronize(Duration clockElapsed) {
    if (completed || _status == AmrapAttemptStatus.incomplete) return;
    final wholeElapsed = Duration(seconds: clockElapsed.inSeconds);
    if (wholeElapsed <= _lastClockElapsed) return;
    final requestedDelta = wholeElapsed - _lastClockElapsed;
    final delta = requestedDelta > activeRemaining
        ? activeRemaining
        : requestedDelta;
    _lastClockElapsed += requestedDelta;
    if (delta == Duration.zero) return;
    _activeElapsed += delta;
    _currentLapDuration += delta;
    _buttonDelayRemaining = delta >= _buttonDelayRemaining
        ? Duration.zero
        : _buttonDelayRemaining - delta;
    _status = activeRemaining == Duration.zero
        ? AmrapAttemptStatus.completed
        : AmrapAttemptStatus.running;
  }

  bool canRecordLap({required bool paused}) =>
      !paused &&
      _status == AmrapAttemptStatus.running &&
      activeRemaining > Duration.zero &&
      _currentLapDuration > Duration.zero &&
      _buttonDelayRemaining == Duration.zero &&
      !limitReached;

  bool recordLap(Duration clockElapsed, {required bool paused}) {
    synchronize(clockElapsed);
    if (!canRecordLap(paused: paused)) return false;
    _completedLaps.add(_currentLapDuration);
    _currentLapDuration = Duration.zero;
    _buttonDelayRemaining = BusinessLimits.maximumAmrapButtonDelay;
    return true;
  }

  bool undoLastLap(Duration clockElapsed) {
    synchronize(clockElapsed);
    if (!canUndoLastLap) return false;
    _currentLapDuration += _completedLaps.removeLast();
    return true;
  }

  void markIncomplete(Duration clockElapsed) {
    synchronize(clockElapsed);
    if (!completed && started) _status = AmrapAttemptStatus.incomplete;
  }

  void markCompleted(Duration clockElapsed) {
    synchronize(clockElapsed);
    if (activeRemaining == Duration.zero) {
      _status = AmrapAttemptStatus.completed;
    }
  }

  void restart() {
    _activeElapsed = Duration.zero;
    _completedLaps.clear();
    _currentLapDuration = Duration.zero;
    _buttonDelayRemaining = Duration.zero;
    _lastClockElapsed = Duration.zero;
    _status = AmrapAttemptStatus.notStarted;
  }

  AmrapExecutionSnapshot snapshot({required bool paused}) =>
      AmrapExecutionSnapshot(
        activeRemaining: activeRemaining,
        currentLapDuration: _currentLapDuration,
        completedLapDurations: completedLapDurations,
        buttonDelayRemaining: _buttonDelayRemaining,
        canRecordLap: canRecordLap(paused: paused),
        canUndoLastLap: canUndoLastLap,
        limitReached: limitReached,
        completed: completed,
      );

  AmrapCheckpointState toCheckpoint() => AmrapCheckpointState(
    configuredDuration: _configuredDuration,
    activeElapsed: _activeElapsed,
    activeRemaining: activeRemaining,
    completedLapDurations: _completedLaps,
    currentLapDuration: _currentLapDuration,
    buttonDelayRemaining: _buttonDelayRemaining,
    completed: completed,
    incomplete: _status == AmrapAttemptStatus.incomplete,
  );

  AmrapHistoryData toHistory({required bool stepCompleted}) => AmrapHistoryData(
    configuredDuration: _configuredDuration,
    activeDuration: _activeElapsed,
    completedLapDurations: _completedLaps,
    partialLapDuration: _currentLapDuration > Duration.zero
        ? _currentLapDuration
        : null,
    completed: stepCompleted,
  );
}

class AmrapExecutionSnapshot {
  const AmrapExecutionSnapshot({
    required this.activeRemaining,
    required this.currentLapDuration,
    required this.completedLapDurations,
    required this.buttonDelayRemaining,
    required this.canRecordLap,
    required this.canUndoLastLap,
    required this.limitReached,
    required this.completed,
  });

  final Duration activeRemaining;
  final Duration currentLapDuration;
  final List<Duration> completedLapDurations;
  final Duration buttonDelayRemaining;
  final bool canRecordLap;
  final bool canUndoLastLap;
  final bool limitReached;
  final bool completed;

  int get completedLapCount => completedLapDurations.length;
  Duration? get lastCompletedLap =>
      completedLapDurations.isEmpty ? null : completedLapDurations.last;
}
