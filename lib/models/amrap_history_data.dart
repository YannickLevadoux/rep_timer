import 'package:flutter/foundation.dart';

import '../validation/amrap_execution_validation.dart';

/// Détail des tours d'une occurrence AMRAP conservée dans l'historique.
@immutable
class AmrapHistoryData {
  factory AmrapHistoryData({
    required Duration configuredDuration,
    required Duration activeDuration,
    required List<Duration> completedLapDurations,
    Duration? partialLapDuration,
    required bool completed,
  }) {
    AmrapExecutionValidation.requireHistory(
      configuredDuration: configuredDuration,
      activeDuration: activeDuration,
      completedLaps: completedLapDurations,
      partialLapDuration: partialLapDuration,
      completed: completed,
    );
    return AmrapHistoryData._(
      configuredDuration: configuredDuration,
      activeDuration: activeDuration,
      completedLapDurations: List.unmodifiable(completedLapDurations),
      partialLapDuration: partialLapDuration,
      completed: completed,
    );
  }

  const AmrapHistoryData._({
    required this.configuredDuration,
    required this.activeDuration,
    required this.completedLapDurations,
    required this.partialLapDuration,
    required this.completed,
  });

  final Duration configuredDuration;
  final Duration activeDuration;
  final List<Duration> completedLapDurations;
  final Duration? partialLapDuration;
  final bool completed;

  AmrapHistoryData copy() => AmrapHistoryData(
    configuredDuration: configuredDuration,
    activeDuration: activeDuration,
    completedLapDurations: completedLapDurations,
    partialLapDuration: partialLapDuration,
    completed: completed,
  );

  Map<String, dynamic> toJson() => {
    'configuredDurationSeconds': configuredDuration.inSeconds,
    'activeDurationSeconds': activeDuration.inSeconds,
    'completedLapDurationsSeconds': completedLapDurations
        .map((duration) => duration.inSeconds)
        .toList(),
    'partialLapDurationSeconds': partialLapDuration?.inSeconds,
    'completed': completed,
  };

  factory AmrapHistoryData.fromJson(Map<String, dynamic> json) =>
      AmrapHistoryData(
        configuredDuration: Duration(
          seconds: json['configuredDurationSeconds'] as int,
        ),
        activeDuration: Duration(seconds: json['activeDurationSeconds'] as int),
        completedLapDurations:
            (json['completedLapDurationsSeconds'] as List<dynamic>)
                .map((value) => Duration(seconds: value as int))
                .toList(),
        partialLapDuration: json['partialLapDurationSeconds'] == null
            ? null
            : Duration(seconds: json['partialLapDurationSeconds'] as int),
        completed: json['completed'] as bool,
      );
}
