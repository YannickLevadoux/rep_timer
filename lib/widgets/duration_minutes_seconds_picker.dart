import 'package:flutter/material.dart';

import '../utils/validation_messages.dart';
import '../validation/business_validation.dart';
import 'number_wheel_field.dart';

/// Durée par défaut pour tout nouvel exercice basé sur une durée ou toute
/// nouvelle pause : 1 minute 30.
const Duration defaultExerciseDuration = Duration(minutes: 1, seconds: 30);

/// Saisie d'une durée via deux roues (Minutes 0-120, Secondes 0-59) sur
/// la même ligne. Le stockage reste inchangé (Duration / secondes en
/// interne) : ce widget ne fait que convertir minutes/secondes <-> Duration
/// de façon transparente pour l'appelant.
class DurationMinutesSecondsPicker extends StatelessWidget {
  final Duration value;
  final ValueChanged<Duration> onChanged;
  final Duration minimum;
  final Duration maximum;
  final bool constrainPickerToBounds;

  const DurationMinutesSecondsPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.minimum = BusinessLimits.minimumDuration,
    this.maximum = BusinessLimits.maximumDuration,
    this.constrainPickerToBounds = false,
  });

  @override
  Widget build(BuildContext context) {
    final minimumMinutes = constrainPickerToBounds ? minimum.inMinutes : 0;
    final maximumMinutes = constrainPickerToBounds
        ? maximum.inMinutes
        : BusinessLimits.maximumDuration.inMinutes;
    final minutes = value.inMinutes.clamp(minimumMinutes, maximumMinutes);
    final seconds = value.inSeconds.remainder(60);
    final minimumSeconds = constrainPickerToBounds && minutes == minimumMinutes
        ? minimum.inSeconds.remainder(60)
        : 0;
    final maximumSeconds = constrainPickerToBounds && minutes == maximumMinutes
        ? maximum.inSeconds.remainder(60)
        : 59;
    final displayedSeconds = seconds.clamp(minimumSeconds, maximumSeconds);
    final issue = value < minimum
        ? BusinessValidationIssue(
            field: BusinessField.duration,
            code: BusinessValidationCode.belowMinimum,
            minimum: minimum.inSeconds,
          )
        : value > maximum
        ? BusinessValidationIssue(
            field: BusinessField.duration,
            code: BusinessValidationCode.aboveMaximum,
            maximum: maximum.inSeconds,
          )
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NumberWheelField(
              min: minimumMinutes,
              max: maximumMinutes,
              value: minutes,
              label: "min",
              onChanged: (m) {
                final selectedMinimumSeconds =
                    constrainPickerToBounds && m == minimumMinutes
                    ? minimum.inSeconds.remainder(60)
                    : 0;
                final selectedMaximumSeconds =
                    constrainPickerToBounds && m == maximumMinutes
                    ? maximum.inSeconds.remainder(60)
                    : 59;
                onChanged(
                  Duration(
                    minutes: m,
                    seconds: seconds.clamp(
                      selectedMinimumSeconds,
                      selectedMaximumSeconds,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                ":",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(width: 12),
            NumberWheelField(
              min: minimumSeconds,
              max: maximumSeconds,
              value: displayedSeconds,
              label: "s",
              onChanged: (s) =>
                  onChanged(Duration(minutes: minutes, seconds: s)),
            ),
          ],
        ),
        if (issue != null)
          Semantics(
            liveRegion: true,
            child: Text(
              validationMessage(issue),
              key: const Key('duration-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}
