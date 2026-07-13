import 'package:flutter/material.dart';

import '../duration_minutes_seconds_picker.dart';

/// Dialogue unique pour créer ou modifier une pause : ne porte que la
/// durée (le nom d'une pause est toujours "Pause", non éditable).
///
/// - Mode création : laisser [initial] à `null` (démarre à
///   [defaultExerciseDuration]) ; titre "Nouvelle pause", bouton "Ajouter".
/// - Mode édition : passer la durée actuelle dans [initial] ; titre
///   "Modifier la pause", bouton "Valider".
///
/// Retourne la [Duration] choisie, ou `null` si annulé. Le bouton de
/// validation reste inactif tant que la durée est nulle (0s).
Future<Duration?> showRestDialog(BuildContext context, {Duration? initial}) {
  final isEditing = initial != null;
  Duration selectedDuration = initial ?? defaultExerciseDuration;

  return showDialog<Duration>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? "Modifier la pause" : "Nouvelle pause"),
            content: SingleChildScrollView(
              child: DurationMinutesSecondsPicker(
                value: selectedDuration,
                onChanged: (d) => setDialogState(() => selectedDuration = d),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
              FilledButton(
                onPressed: () {
                  if (selectedDuration.inSeconds <= 0) return;
                  Navigator.pop(context, selectedDuration);
                },
                child: Text(isEditing ? "Valider" : "Ajouter"),
              ),
            ],
          );
        },
      );
    },
  );
}
