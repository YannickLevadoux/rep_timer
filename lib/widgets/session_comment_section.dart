import 'package:flutter/material.dart';

import '../models/training_item.dart';

/// Commentaire de l'exercice en cours, sur l'écran d'exécution de séance :
/// si absent, affiche un lien discret pour en ajouter un (sauf pour les
/// pauses, qui n'ont jamais de commentaire) ; si présent, il clignote
/// avec le nom/l'icône de l'exercice (même animation partagée, via
/// [blinkOpacity]), et un crayon stable permet de le modifier.
class SessionCommentSection extends StatelessWidget {
  final TrainingItem item;
  final Animation<double> blinkOpacity;
  final VoidCallback onEditComment;

  const SessionCommentSection({
    super.key,
    required this.item,
    required this.blinkOpacity,
    required this.onEditComment,
  });

  @override
  Widget build(BuildContext context) {
    final comment = item.comment;

    if (comment == null || comment.isEmpty) {
      // Les commentaires sont propres aux exercices : pour une pause,
      // on n'affiche ni commentaire ni lien pour en ajouter un.
      if (item.type == ItemType.rest) {
        return const SizedBox.shrink();
      }

      // Rien à afficher pour le commentaire lui-même ; seul un lien
      // discret permet d'en ajouter un (n'est pas censé clignoter,
      // c'est une action, pas une information sur l'exercice).
      return TextButton.icon(
        onPressed: onEditComment,
        icon: const Icon(Icons.add_comment, size: 16),
        label: const Text(
          "Ajouter un commentaire",
          style: TextStyle(fontSize: 12),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: FadeTransition(
            opacity: blinkOpacity,
            child: Text(
              comment,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.edit, size: 16),
          tooltip: "Modifier le commentaire",
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          visualDensity: VisualDensity.compact,
          onPressed: onEditComment,
        ),
      ],
    );
  }
}
