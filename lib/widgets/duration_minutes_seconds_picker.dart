import 'package:flutter/material.dart';

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

  const DurationMinutesSecondsPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = value.inMinutes.clamp(0, 120);
    final seconds = value.inSeconds.remainder(60);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NumberWheelField(
          min: 0,
          max: 120,
          value: minutes,
          label: "min",
          onChanged: (m) => onChanged(Duration(minutes: m, seconds: seconds)),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(":", style: Theme.of(context).textTheme.headlineSmall),
        ),
        const SizedBox(width: 12),
        NumberWheelField(
          min: 0,
          max: 59,
          value: seconds,
          label: "s",
          onChanged: (s) => onChanged(Duration(minutes: minutes, seconds: s)),
        ),
      ],
    );
  }
}
