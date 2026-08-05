import 'package:flutter/material.dart';

import '../utils/validation_messages.dart';
import '../validation/business_validation.dart';

/// Sélecteur du nombre de répétitions d'un groupe : boutons +/- de part
/// et d'autre de la valeur courante. Le bouton "-" est désactivé sous 1
/// répétition (minimum imposé par le modèle, voir [ExerciseGroup.rounds]).
class RoundsEditor extends StatelessWidget {
  final int rounds;
  final ValueChanged<int> onChanged;

  const RoundsEditor({
    super.key,
    required this.rounds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final issue = BusinessValidation.validateCount(
      rounds,
      field: BusinessField.groupRounds,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            const Text("Répétitions"),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: "Moins de répétitions",
                  onPressed: rounds > BusinessLimits.minimumCount
                      ? () => onChanged(rounds - 1)
                      : null,
                ),
                Text(
                  '$rounds',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: "Plus de répétitions",
                  onPressed: rounds < BusinessLimits.maximumCount
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
