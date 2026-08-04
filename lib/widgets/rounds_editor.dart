import 'package:flutter/material.dart';

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
    return Wrap(
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
              onPressed: rounds > 1 ? () => onChanged(rounds - 1) : null,
            ),
            Text(
              '$rounds',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: "Plus de répétitions",
              onPressed: () => onChanged(rounds + 1),
            ),
          ],
        ),
      ],
    );
  }
}
