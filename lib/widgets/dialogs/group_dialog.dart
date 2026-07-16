import 'package:flutter/material.dart';

import 'app_form_dialog.dart';

/// Dialogue de création d'un nouveau groupe (nom + nombre de répétitions
/// du groupe). Retourne le texte brut saisi par l'utilisateur, sans
/// validation ni parsing (c'est à l'appelant de vérifier que le nom n'est
/// pas vide et de parser le nombre de répétitions, exactement comme
/// avant l'extraction de ce dialogue).
Future<({String name, String roundsText})?> showNewGroupDialog(
  BuildContext context,
) {
  final nameController = TextEditingController();
  final roundsController = TextEditingController(text: "1");

  return showAppFormDialog<({String name, String roundsText})>(
    context,
    title: "Nouveau groupe",
    contentBuilder: (context, setDialogState) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Ex : Échauffement"),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: roundsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Nombre de répétitions du groupe",
          ),
        ),
      ],
    ),
    confirmLabel: "Ajouter",
    onConfirm: () =>
        (name: nameController.text, roundsText: roundsController.text),
  );
}

/// Dialogue de renommage d'un groupe existant, pré-rempli avec son nom
/// actuel. Retourne le nouveau nom brut (à trim/valider par l'appelant),
/// ou `null` si annulé.
Future<String?> showRenameGroupDialog(
  BuildContext context, {
  required String initialName,
}) {
  final controller = TextEditingController(text: initialName);

  return showAppFormDialog<String>(
    context,
    title: "Renommer le groupe",
    contentBuilder: (context, setDialogState) => TextField(
      controller: controller,
      autofocus: true,
      decoration: const InputDecoration(hintText: "Ex : Échauffement"),
    ),
    confirmLabel: "Valider",
    onConfirm: () => controller.text,
  );
}
