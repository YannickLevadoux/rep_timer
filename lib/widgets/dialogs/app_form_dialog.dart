import 'package:flutter/material.dart';

/// Structure commune à tous les dialogues "Annuler / action" de
/// l'application : un [AlertDialog] avec un titre, un contenu, et deux
/// actions — "Annuler" puis un bouton de validation.
///
/// [contentBuilder] reçoit un [StateSetter] local permettant aux
/// dialogues ayant un état interne (ex : mode sélectionné, durée en cours
/// de saisie) de se reconstruire sans fermer le dialogue.
///
/// [onConfirm] est appelé au clic sur le bouton de validation. S'il
/// retourne `null`, le dialogue reste ouvert (permet de bloquer la
/// validation tant qu'un champ n'est pas valide, ex : durée nulle).
/// Sinon, le dialogue se ferme en retournant cette valeur.
Future<T?> showAppFormDialog<T extends Object>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext context, StateSetter setDialogState)
  contentBuilder,
  required String confirmLabel,
  required T? Function() onConfirm,
  String cancelLabel = "Annuler",
  ButtonStyle? confirmButtonStyle,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: contentBuilder(context, setDialogState),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(cancelLabel),
              ),
              FilledButton(
                style: confirmButtonStyle,
                onPressed: () {
                  final result = onConfirm();
                  if (result != null) {
                    Navigator.pop(context, result);
                  }
                },
                child: Text(confirmLabel),
              ),
            ],
          );
        },
      );
    },
  );
}
