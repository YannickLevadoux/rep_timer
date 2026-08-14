import 'package:flutter/material.dart';

import '../utils/validation_messages.dart';
import '../validation/business_validation.dart';

/// Sélecteur du nombre de répétitions d'un groupe : boutons +/- de part
/// et d'autre de la valeur courante. Le bouton "-" est désactivé sous 1
/// répétition (minimum imposé par le modèle, voir [ExerciseGroup.rounds]).
class RoundsEditor extends StatelessWidget {
  final int rounds;
  final ValueChanged<int> onChanged;
  final String label;
  final int minimum;
  final int maximum;

  const RoundsEditor({
    super.key,
    required this.rounds,
    required this.onChanged,
    this.label = 'Répétitions',
    this.minimum = BusinessLimits.minimumCount,
    this.maximum = BusinessLimits.maximumCount,
  });

  @override
  Widget build(BuildContext context) {
    final issue = rounds < minimum
        ? BusinessValidationIssue(
            field: BusinessField.groupRounds,
            code: BusinessValidationCode.belowMinimum,
            minimum: minimum,
          )
        : rounds > maximum
        ? BusinessValidationIssue(
            field: BusinessField.groupRounds,
            code: BusinessValidationCode.aboveMaximum,
            maximum: maximum,
          )
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            Text(label),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: label == 'Répétitions'
                      ? 'Moins de répétitions'
                      : 'Diminuer $label',
                  onPressed: rounds > minimum
                      ? () => onChanged(rounds - 1)
                      : null,
                ),
                Text(
                  '$rounds',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: label == 'Répétitions'
                      ? 'Plus de répétitions'
                      : 'Augmenter $label',
                  onPressed: rounds < maximum
                      ? () => onChanged(rounds + 1)
                      : null,
                ),
              ],
            ),
          ],
        ),
        if (issue != null)
          Semantics(
            liveRegion: true,
            child: Text(
              validationMessage(issue),
              key: const Key('rounds-error'),
              textAlign: TextAlign.end,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}
