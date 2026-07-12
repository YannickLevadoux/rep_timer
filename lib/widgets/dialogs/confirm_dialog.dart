import 'package:flutter/material.dart';

/// Dialogue de confirmation générique à deux choix (Annuler / action),
/// avec un style cohérent dans toute l'application : bouton d'action
/// teinté en rouge (colorScheme.error) si [isDestructive].
///
/// Retourne `true` si l'action a été confirmée, `false` sinon (annulée ou
/// fermée sans choix explicite).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  required String confirmLabel,
  String cancelLabel = "Annuler",
  bool isDestructive = true,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}

/// Dialogue à 3 choix pour la gestion des modifications non enregistrées
/// à la fermeture de l'écran d'édition.
///
/// Retourne `'save'`, `'discard'`, `'cancel'`, ou `null` (fermeture sans
/// choix explicite — à traiter comme `'cancel'` par l'appelant).
Future<String?> showUnsavedChangesDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Modifications non enregistrées"),
        content: const Text(
          "Vous avez des modifications non enregistrées. Que souhaitez-vous faire ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text("Annuler"),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text("Abandonner les modifications"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text("Enregistrer"),
          ),
        ],
      );
    },
  );
}