import 'package:flutter/material.dart';

/// Choix proposés à l'utilisateur lorsqu'il souhaite quitter une séance
/// en cours d'exécution (voir [showExitSessionDialog]).
enum ExitSessionChoice {
  /// Reprendre la séance là où elle en était (aucun changement).
  continueSession,

  /// Arrêt anticipé : enregistrée dans l'historique avec le statut
  /// "Incomplète".
  finish,

  /// Abandon : aucune trace conservée, la séance n'est pas enregistrée.
  abandon,
}

/// Menu affiché sur le bouton Retour pendant l'exécution d'une séance :
/// Continuer / Terminer la session (incomplète, enregistrée) / Abandonner
/// (aucune trace conservée).
///
/// Retourne `null` si le dialogue est fermé sans choix explicite — à
/// traiter comme [ExitSessionChoice.continueSession] par l'appelant.
Future<ExitSessionChoice?> showExitSessionDialog(BuildContext context) {
  return showDialog<ExitSessionChoice>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Quitter la séance ?"),
        content: const Text("Que souhaitez-vous faire ?"),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, ExitSessionChoice.continueSession),
            child: const Text("Continuer la séance"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ExitSessionChoice.finish),
            child: const Text("Terminer la session"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, ExitSessionChoice.abandon),
            child: const Text("Abandonner"),
          ),
        ],
      );
    },
  );
}
