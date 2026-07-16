import 'package:flutter/material.dart';

import '../duration_minutes_seconds_picker.dart';
import 'app_form_dialog.dart';

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

  return showAppFormDialog<Duration>(
    context,
    title: isEditing ? "Modifier la pause" : "Nouvelle pause",
    contentBuilder: (context, setDialogState) => SingleChildScrollView(
      child: DurationMinutesSecondsPicker(
        value: selectedDuration,
        onChanged: (d) => setDialogState(() => selectedDuration = d),
      ),
    ),
    confirmLabel: isEditing ? "Valider" : "Ajouter",
    onConfirm: () => selectedDuration.inSeconds <= 0 ? null : selectedDuration,
  );
}
