import 'validation_contract.dart';

/// Validation des instantanés d'exécution AMRAP persistés.
abstract final class AmrapExecutionValidation {
  static void requireCheckpoint({
    required Duration configuredDuration,
    required Duration activeElapsed,
    required Duration activeRemaining,
    required List<Duration> completedLaps,
    required Duration currentLapDuration,
    required Duration buttonDelayRemaining,
    required bool completed,
    bool incomplete = false,
  }) {
    _requireConfiguredDuration(configuredDuration);
    _requireWholeNonNegative(activeElapsed, 'activeElapsed');
    _requireWholeNonNegative(activeRemaining, 'activeRemaining');
    _requireLaps(completedLaps);
    _requireWholeNonNegative(currentLapDuration, 'currentLapDuration');
    _requireWholeNonNegative(buttonDelayRemaining, 'buttonDelayRemaining');
    if (buttonDelayRemaining > BusinessLimits.maximumAmrapButtonDelay ||
        activeElapsed + activeRemaining != configuredDuration ||
        _sum(completedLaps) + currentLapDuration != activeElapsed ||
        (completed && activeRemaining != Duration.zero) ||
        (incomplete && (completed || activeElapsed == Duration.zero))) {
      throw const FormatException('État de checkpoint AMRAP incohérent.');
    }
  }

  static void requireHistory({
    required Duration configuredDuration,
    required Duration activeDuration,
    required List<Duration> completedLaps,
    required Duration? partialLapDuration,
    required bool completed,
  }) {
    _requireConfiguredDuration(configuredDuration);
    _requireWholeNonNegative(activeDuration, 'activeDuration');
    _requireLaps(completedLaps);
    if (partialLapDuration != null) {
      _requireWholePositive(partialLapDuration, 'partialLapDuration');
    }
    if (activeDuration > configuredDuration ||
        _sum(completedLaps) + (partialLapDuration ?? Duration.zero) !=
            activeDuration ||
        (completed && activeDuration != configuredDuration)) {
      throw const FormatException('Historique AMRAP incohérent.');
    }
  }

  static void _requireConfiguredDuration(Duration value) {
    _requireWholePositive(value, 'configuredDuration');
    if (value < BusinessLimits.minimumAmrapDuration ||
        value > BusinessLimits.maximumAmrapDuration) {
      throw const FormatException('Durée AMRAP hors bornes.');
    }
  }

  static void _requireLaps(List<Duration> laps) {
    if (laps.length > BusinessLimits.maximumAmrapLaps) {
      throw const FormatException('Trop de tours AMRAP.');
    }
    for (final lap in laps) {
      _requireWholePositive(lap, 'completedLapDuration');
    }
  }

  static void _requireWholePositive(Duration value, String field) {
    _requireWholeNonNegative(value, field);
    if (value == Duration.zero) {
      throw FormatException('$field doit être strictement positif.');
    }
  }

  static void _requireWholeNonNegative(Duration value, String field) {
    if (value.isNegative || value != Duration(seconds: value.inSeconds)) {
      throw FormatException('$field doit contenir des secondes entières.');
    }
  }

  static Duration _sum(List<Duration> values) =>
      values.fold(Duration.zero, (total, value) => total + value);
}
