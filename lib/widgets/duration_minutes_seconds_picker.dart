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

  const DurationMinutesSecondsPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.minimum = BusinessLimits.minimumDuration,
    this.maximum = BusinessLimits.maximumDuration,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = value.inMinutes.clamp(
      0,
      BusinessLimits.maximumDuration.inMinutes,
    );
    final seconds = value.inSeconds.remainder(60);
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
              min: 0,
              max: BusinessLimits.maximumDuration.inMinutes,
              value: minutes,
              label: "min",
              onChanged: (m) =>
                  onChanged(Duration(minutes: m, seconds: seconds)),
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
              min: 0,
              max: 59,
              value: seconds,
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
