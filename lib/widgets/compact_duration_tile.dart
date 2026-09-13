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
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(formatDuration(value)),
    trailing: Wrap(
      children: [
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
