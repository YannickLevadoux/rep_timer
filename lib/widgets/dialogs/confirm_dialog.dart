import 'package:flutter/material.dart';

import 'app_form_dialog.dart';

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
  final confirmed = await showAppFormDialog<bool>(
    context,
    title: title,
    contentBuilder: (context, setDialogState) => Text(content),
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    confirmButtonStyle: isDestructive
        ? FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          )
        : null,
    onConfirm: () => true,
  );

  return confirmed ?? false;
}

/// Enchaîne un [showConfirmDialog] de suppression avec l'action de
/// suppression elle-même : évite de répéter ce couple dans chaque écran
/// qui propose de supprimer une entité (séance, entrée d'historique...).
///
/// Retourne `true` si la suppression a été confirmée et exécutée, `false`
/// si l'utilisateur a annulé (dans ce cas, [onDelete] n'est jamais
/// appelé). C'est à l'appelant de gérer la suite (retour d'écran, mise à
/// jour de sa liste locale...), qui diffère légitimement d'un écran à
/// l'autre.
Future<bool> confirmAndDelete(
  BuildContext context, {
  required String title,
  required String content,
  required Future<void> Function() onDelete,
}) async {
  final confirmed = await showConfirmDialog(
    context,
    title: title,
    content: content,
    confirmLabel: "Supprimer",
  );

  if (!confirmed) return false;

  await onDelete();
  return true;
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
