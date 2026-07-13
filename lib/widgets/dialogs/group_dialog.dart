import 'package:flutter/material.dart';

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

  return showDialog<({String name, String roundsText})>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Nouveau groupe"),
        content: Column(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, (
                name: nameController.text,
                roundsText: roundsController.text,
              ));
            },
            child: const Text("Ajouter"),
          ),
        ],
      );
    },
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

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Renommer le groupe"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Ex : Échauffement"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Valider"),
          ),
        ],
      );
    },
  );
}
