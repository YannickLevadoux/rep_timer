import 'package:flutter/material.dart';

/// Bloc de section réutilisable pour l'écran Paramètres : un titre suivi
/// de ses lignes de réglages. Ajouter une nouvelle section de paramètres
/// à l'avenir se résume à instancier ce widget avec un nouveau titre et
/// de nouveaux enfants, sans toucher au reste de l'écran.
class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...children,
        const Divider(height: 1),
      ],
    );
  }
}