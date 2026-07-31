import 'package:flutter/material.dart';

import '../../services/app_settings_storage.dart';
import 'app_form_dialog.dart';

/// Dialogue de réglages accessible depuis l'icône roue crantée de
/// [GroupEditor] : un unique réglage pour l'instant (préremplissage du
/// nom des nouveaux exercices avec le nom du groupe), lu et persisté via
/// [AppSettingsStorage] — la même préférence que celle affichée dans la
/// section "Édition" de l'écran Paramètres. Les deux interfaces restent
/// synchronisées car chacune relit la valeur enregistrée à chaque
/// ouverture, plutôt que de partager un état en mémoire.
///
/// "Annuler" ferme le dialogue sans rien persister : la valeur du switch
/// n'est modifiée qu'en mémoire locale au dialogue tant que "Valider"
/// n'a pas été pressé, donc la préférence réellement enregistrée reste
/// automatiquement celle d'avant l'ouverture.
Future<void> showGroupEditorSettingsDialog(BuildContext context) async {
  final storage = AppSettingsStorage();
  final initialValue = await storage.loadPrefillExerciseName();

  if (!context.mounted) return;

  var currentValue = initialValue;

  final confirmed = await showAppFormDialog<bool>(
    context,
    title: "Paramètres du groupe",
    contentBuilder: (context, setDialogState) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(child: Text("Préremplir le nom des nouveaux exercices")),
        Switch(
          value: currentValue,
          onChanged: (value) => setDialogState(() => currentValue = value),
        ),
      ],
    ),
    confirmLabel: "Valider",
    onConfirm: () => true,
  );

  if (confirmed == true) {
    await storage.savePrefillExerciseName(currentValue);
  }
}
