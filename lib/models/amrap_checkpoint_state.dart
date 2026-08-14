import 'package:flutter/foundation.dart';

import '../validation/amrap_execution_validation.dart';

/// État interne nécessaire à la reprise exacte d'une étape AMRAP.
@immutable
class AmrapCheckpointState {
  factory AmrapCheckpointState({
    required Duration configuredDuration,
    required Duration activeElapsed,
    required Duration activeRemaining,
    required List<Duration> completedLapDurations,
    required Duration currentLapDuration,
    required Duration buttonDelayRemaining,
    required bool completed,
    bool incomplete = false,
  }) {
    AmrapExecutionValidation.requireCheckpoint(
      configuredDuration: configuredDuration,
      activeElapsed: activeElapsed,
      activeRemaining: activeRemaining,
      completedLaps: completedLapDurations,
      currentLapDuration: currentLapDuration,
      buttonDelayRemaining: buttonDelayRemaining,
      completed: completed,
      incomplete: incomplete,
    );
    return AmrapCheckpointState._(
      configuredDuration: configuredDuration,
      activeElapsed: activeElapsed,
      activeRemaining: activeRemaining,
      completedLapDurations: List.unmodifiable(completedLapDurations),
      currentLapDuration: currentLapDuration,
      buttonDelayRemaining: buttonDelayRemaining,
      completed: completed,
      incomplete: incomplete,
    );
  }

  const AmrapCheckpointState._({
    required this.configuredDuration,
    required this.activeElapsed,
    required this.activeRemaining,
    required this.completedLapDurations,
    required this.currentLapDuration,
    required this.buttonDelayRemaining,
    required this.completed,
    required this.incomplete,
  });

  final Duration configuredDuration;
  final Duration activeElapsed;
  final Duration activeRemaining;
  final List<Duration> completedLapDurations;
  final Duration currentLapDuration;
  final Duration buttonDelayRemaining;
  final bool completed;
  final bool incomplete;

  AmrapCheckpointState copy() => AmrapCheckpointState(
    configuredDuration: configuredDuration,
    activeElapsed: activeElapsed,
    activeRemaining: activeRemaining,
    completedLapDurations: completedLapDurations,
    currentLapDuration: currentLapDuration,
    buttonDelayRemaining: buttonDelayRemaining,
    completed: completed,
    incomplete: incomplete,
  );

  Map<String, dynamic> toJson() => {
    'configuredDurationSeconds': configuredDuration.inSeconds,
    'activeElapsedSeconds': activeElapsed.inSeconds,
    'activeRemainingSeconds': activeRemaining.inSeconds,
    'completedLapDurationsSeconds': completedLapDurations
        .map((duration) => duration.inSeconds)
        .toList(),
    'currentLapDurationSeconds': currentLapDuration.inSeconds,
    'buttonDelayRemainingSeconds': buttonDelayRemaining.inSeconds,
    'completed': completed,
    'incomplete': incomplete,
  };

  factory AmrapCheckpointState.fromJson(Map<String, dynamic> json) =>
      AmrapCheckpointState(
        configuredDuration: _duration(json, 'configuredDurationSeconds'),
        activeElapsed: _duration(json, 'activeElapsedSeconds'),
        activeRemaining: _duration(json, 'activeRemainingSeconds'),
        completedLapDurations:
            (json['completedLapDurationsSeconds'] as List<dynamic>)
                .map((value) => Duration(seconds: value as int))
                .toList(),
        currentLapDuration: _duration(json, 'currentLapDurationSeconds'),
        buttonDelayRemaining: _duration(json, 'buttonDelayRemainingSeconds'),
        completed: json['completed'] as bool,
        incomplete: json['incomplete'] as bool? ?? false,
      );

  static Duration _duration(Map<String, dynamic> json, String key) =>
      Duration(seconds: json[key] as int);
}
