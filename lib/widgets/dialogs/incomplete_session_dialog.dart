import 'package:flutter/material.dart';

/// Choix proposés lorsque la séance atteint sa dernière étape possible
/// (dernier exercice du dernier groupe) alors que des exercices ou
/// pauses n'ont jamais été réalisés (ordre modifié manuellement en cours
/// de séance, machine occupée...).
enum IncompleteSessionChoice {
  /// Rouvre l'écran de progression pour choisir où reprendre.
  chooseStep,

  /// Arrête définitivement la séance ; enregistrée avec le statut
  /// Incomplète (voir SessionController.finishSession).
  finish,
}

/// Boîte de dialogue affichée par [TrainingSessionScreen] dès que
/// `SessionController.pendingIncompleteReview` passe à `true`.
///
/// Volontairement non-annulable (pas de fermeture par le bouton retour
/// ni en touchant en dehors) : la séance est en pause en attendant une
/// décision explicite, un des deux boutons doit être pressé.
Future<IncompleteSessionChoice?> showIncompleteSessionDialog(
  BuildContext context,
) {
  return showDialog<IncompleteSessionChoice>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text("Séance incomplète"),
          content: const Text(
            "La séance est incomplète. Que souhaitez-vous faire ?",
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, IncompleteSessionChoice.chooseStep),
              child: const Text("Reprendre à un exercice de mon choix"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () =>
                  Navigator.pop(context, IncompleteSessionChoice.finish),
              child: const Text("Terminer la séance"),
            ),
          ],
        ),
      );
    },
  );
}
