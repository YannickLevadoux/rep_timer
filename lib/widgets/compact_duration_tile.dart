import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class CompactDurationTile extends StatelessWidget {
  const CompactDurationTile({
    super.key,
    required this.title,
    required this.value,
    required this.onEdit,
    this.onDelete,
  });

  final String title;
  final Duration value;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 3),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.timer, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                formatDuration(value),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onEdit,
          tooltip: 'Modifier $title',
          icon: const Icon(Icons.edit_outlined),
        ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            tooltip: 'Supprimer $title',
            icon: const Icon(Icons.delete_outline),
          ),
      ],
    ),
  );
}
