import 'package:flutter/material.dart';

/// Dialogue d'édition du commentaire de l'exercice en cours, positionné
/// en haut de l'écran : Valider/Annuler restent ainsi toujours visibles
/// même quand le clavier Android est affiché, sans avoir besoin de faire
/// défiler l'écran.
///
/// Retourne le texte brut saisi (à trim par l'appelant), ou `null` si
/// annulé (bouton ou fermeture du dialogue) : dans ce cas, le commentaire
/// précédent doit être conservé tel quel.
Future<String?> showCommentDialog(
  BuildContext context, {
  required String initialComment,
}) async {
  final controller = TextEditingController(text: initialComment);
  final focusNode = FocusNode();

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Commentaire",
                style: Theme.of(dialogContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                maxLines: 3,
                minLines: 1,
                // Comportement par défaut d'un champ multiligne : la
                // touche Entrée insère un retour à la ligne, inchangé.
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Poids, intensité...",
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text("Annuler"),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(dialogContext, controller.text),
                    child: const Text("Valider"),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  controller.dispose();
  focusNode.dispose();

  return result;
}
