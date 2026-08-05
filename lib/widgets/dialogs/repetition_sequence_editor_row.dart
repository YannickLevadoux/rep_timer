import 'package:flutter/material.dart';

/// État éditable d'un tour de la suite. La clé reste associée à sa valeur
/// pendant un glisser-déposer, indépendamment de sa position dans la liste.
class RepetitionSequenceEntry {
  RepetitionSequenceEntry(int value)
    : key = UniqueKey(),
      controller = TextEditingController(text: value.toString());

  final Key key;
  final TextEditingController controller;
  String? error;

  void dispose() => controller.dispose();
}

/// Ligne compacte d'un tour : valeur, suppression et poignée de déplacement.
class RepetitionSequenceEditorRow extends StatelessWidget {
  const RepetitionSequenceEditorRow({
    super.key,
    required this.index,
    required this.entry,
    required this.canDelete,
    required this.onDelete,
  });

  final int index;
  final RepetitionSequenceEntry entry;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Tour\n${index + 1}',
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: entry.controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Répétitions',
                errorText: entry.error,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Supprimer le tour',
            constraints: const BoxConstraints.tightFor(width: 40, height: 48),
            onPressed: canDelete ? onDelete : null,
            icon: const Icon(Icons.delete_outline),
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Tooltip(
              message: 'Réordonner',
              child: SizedBox.square(
                dimension: 40,
                child: Icon(Icons.drag_handle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
