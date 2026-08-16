import 'package:flutter/material.dart';

/// Bouton d'aide réutilisable ouvrant un dialogue d'information Material.
class ContextualHelpButton extends StatelessWidget {
  final String title;
  final Widget content;
  final Widget icon;
  final String tooltip;

  const ContextualHelpButton({
    super.key,
    required this.title,
    required this.content,
    this.icon = const Icon(Icons.info_outline),
    this.tooltip = "Plus d'informations",
  });

  Future<void> _showHelp(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(title),
        content: content,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: IconButton(
        tooltip: tooltip,
        icon: icon,
        onPressed: () => _showHelp(context),
      ),
    );
  }
}
