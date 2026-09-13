import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/exercise_icons.dart';
import '../../validation/business_validation.dart';
import 'tabata_exercise_entry.dart';

class TabataExerciseEditorRow extends StatelessWidget {
  const TabataExerciseEditorRow({
    super.key,
    required this.index,
    required this.entry,
    required this.canDelete,
    required this.onEditIcon,
    required this.onEditComment,
    required this.onDelete,
  });

  final int index;
  final TabataExerciseEntry entry;
  final bool canDelete;
  final VoidCallback onEditIcon;
  final VoidCallback onEditComment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cycle = index + 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: "Modifier l'icône du cycle $cycle",
            child: Tooltip(
              message: "Modifier l'icône",
              child: InkWell(
                onTap: onEditIcon,
                borderRadius: BorderRadius.circular(24),
                child: SizedBox.square(
                  dimension: 48,
                  child: Icon(iconForExercise(entry.iconName)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cycle $cycle',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                TextField(
                  controller: entry.nameController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 1,
                  maxLength: BusinessLimits.maximumNameCharacters,
                  maxLengthEnforcement: MaxLengthEnforcement.none,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: "Nom de l'exercice",
                    errorText: entry.nameError,
                  ),
                ),
                _CommentAction(
                  comment: entry.comment,
                  error: entry.commentError,
                  onTap: onEditComment,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Supprimer le cycle $cycle",
            onPressed: canDelete ? onDelete : null,
            icon: const Icon(Icons.delete_outline),
          ),
          Semantics(
            label: 'Déplacer le cycle $cycle',
            child: ReorderableDragStartListener(
              index: index,
              child: const Tooltip(
                message: 'Réordonner le cycle',
                child: SizedBox.square(
                  dimension: 48,
                  child: Icon(Icons.drag_handle),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentAction extends StatelessWidget {
  const _CommentAction({this.comment, this.error, required this.onTap});

  final String? comment;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = comment?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: value == null || value.isEmpty
              ? 'Ajouter un commentaire'
              : 'Modifier le commentaire : $value',
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  const Icon(Icons.comment_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      value == null || value.isEmpty ? 'Commentaire' : value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}
