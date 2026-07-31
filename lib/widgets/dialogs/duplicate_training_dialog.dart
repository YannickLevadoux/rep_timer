import 'package:flutter/material.dart';

import 'app_form_dialog.dart';

/// Dialogue de duplication d'une séance : demande le nom de la copie,
/// /// prérempli avec `<nom d'origine> - Copie`.
/// L'utilisateur peut le modifier librement.
///
/// Retourne le nom saisi (trim), ou `null` si annulé (bouton ou fermeture
/// du dialogue) : dans ce cas, aucune duplication ne doit être effectuée.
/// Un nom vide bloque simplement la validation (même comportement que
/// showRestDialog pour un champ invalide), sans message d'erreur
/// supplémentaire.
Future<String?> showDuplicateTrainingDialog(
  BuildContext context, {
  required String originalName,
}) {
  final controller = TextEditingController(text: "$originalName - Copie");

  return showAppFormDialog<String>(
    context,
    title: "Dupliquer la séance",
    contentBuilder: (context, setDialogState) => TextField(
      controller: controller,
      autofocus: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: "Nom de la nouvelle séance",
      ),
    ),
    confirmLabel: "Copier",
    onConfirm: () {
      final name = controller.text.trim();
      return name.isEmpty ? null : name;
    },
  );
}
