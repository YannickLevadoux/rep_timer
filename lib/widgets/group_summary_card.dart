import 'package:flutter/material.dart';

import '../models/exercise_group.dart';
import '../models/training_item.dart';
import '../utils/exercise_icons.dart';

/// Carte de synthèse d'un groupe sur l'écran principal d'édition d'une
/// séance (Training Editor) : uniquement de la consultation (nom, type,
/// répétitions, liste des exercices/pauses en lecture seule). Seules les
/// actions Éditer / Supprimer / réordonner le groupe restent disponibles
/// ici ; toute modification détaillée de son contenu se fait désormais
/// sur l'écran dédié "Édition du groupe".
///
/// Le groupe peut être replié ou déplié en cliquant sur son en-tête (nom
/// + boutons) : replié, seuls l'en-tête et la ligne de synthèse
/// (type/répétitions) restent visibles, la liste des exercices/pauses est
/// masquée. Cet état est purement local à l'affichage (voir
/// [ExerciseGroup.expanded]) : il n'est jamais persisté et ne compte donc
/// pas comme une modification non enregistrée de la séance.
class GroupSummaryCard extends StatelessWidget {
  final ExerciseGroup group;
  final int index;
  final bool expanded;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleExpanded;

  const GroupSummaryCard({
    super.key,
    required this.group,
    required this.index,
    required this.expanded,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : seule zone qui replie/déplie le groupe au clic.
          // Les boutons/poignée ci-dessous gèrent eux-mêmes leurs
          // propres taps et ne déclenchent donc jamais ce basculement.
          InkWell(
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 4, 0),
              child: Row(
                children: [
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: "Éditer le groupe",
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: "Supprimer le groupe",
                    onPressed: onDelete,
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.drag_handle),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                // Même style visuel que "Durée libre" pour un exercice :
                // simple texte discret, sans composant dédié.
                Text(
                  group.type.label,
                  style: TextStyle(fontSize: 13, color: outline),
                ),
                const Spacer(),
                Text(
                  "Répétitions : × ${group.rounds}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Contenu repliable : seule la liste des exercices/pauses est
          // masquée quand le groupe est replié, l'en-tête et la ligne de
          // synthèse ci-dessus restent toujours visibles.
          if (expanded) ...[
            const Divider(height: 1),
            if (group.items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Aucun exercice"),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: group.items
                      .map((item) => _ReadOnlyItemRow(item: item))
                      .toList(),
                ),
              ),
          ] else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Ligne en lecture seule d'un exercice ou d'une pause : icône + nom +
/// détail (durée, répétitions ou "Durée libre"), sans aucune action.
/// Présentation inspirée de l'écran Détail de l'historique.
class _ReadOnlyItemRow extends StatelessWidget {
  final TrainingItem item;

  const _ReadOnlyItemRow({required this.item});

  String get _detail {
    if (item.type == ItemType.rest) {
      return "${item.duration?.inSeconds ?? 0} s";
    }
    if (item.isFreeDuration) return "Durée libre";
    if (item.duration != null) return "${item.duration!.inSeconds} s";
    return "${item.repetitions ?? 0} répétitions";
  }

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(
            item.type == ItemType.rest
                ? Icons.timer
                : iconForExercise(item.iconName),
            size: 18,
            color: outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.type == ItemType.rest ? "Pause" : item.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(_detail, style: TextStyle(fontSize: 13, color: outline)),
        ],
      ),
    );
  }
}
