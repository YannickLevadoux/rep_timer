import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import 'contextual_help_button.dart';
import 'duration_minutes_seconds_picker.dart';

/// Section visuelle associant un titre au sélecteur de durée Quick Tabata.
class QuickTabataDurationSection extends StatelessWidget {
  final String title;
  final Duration value;
  final ValueChanged<Duration> onChanged;

  const QuickTabataDurationSection({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DurationMinutesSecondsPicker(value: value, onChanged: onChanged),
      ],
    );
  }
}

/// Résumé visuel de la durée estimée et de son aide contextuelle.
class QuickTabataEstimatedDurationCard extends StatelessWidget {
  final Duration? duration;

  const QuickTabataEstimatedDurationCard({super.key, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            const Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text("Temps total estimé"),
                ContextualHelpButton(
                  title: "À propos de l'estimation",
                  tooltip: "Informations sur la durée estimée",
                  content: Text(
                    "Cette estimation correspond à la durée programmée de "
                    "la séance. Les pauses intermédiaires sont "
                    "comptabilisées, mais la dernière pause de la séance "
                    "n'est pas exécutée. Les pauses manuelles et la "
                    "navigation pendant la séance ne sont pas incluses.",
                  ),
                ),
              ],
            ),
            Text(
              duration == null ? "Non estimable" : formatDuration(duration!),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
