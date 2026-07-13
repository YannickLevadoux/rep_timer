import 'package:flutter/material.dart';

import '../widgets/settings_section.dart';

/// Écran centralisant les paramètres de l'application, organisé en
/// sections pour faciliter l'ajout de nouveaux réglages à l'avenir.
class SettingsScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  // Logique de changement de thème réutilisée telle quelle depuis
  // l'écran d'accueil (même icône, même cycle Auto -> Clair -> Sombre).
  IconData get _themeIcon => switch (themeMode) {
    ThemeMode.system => Icons.brightness_auto,
    ThemeMode.light => Icons.light_mode,
    ThemeMode.dark => Icons.dark_mode,
  };

  String get _themeLabel => switch (themeMode) {
    ThemeMode.system => "Auto",
    ThemeMode.light => "Clair",
    ThemeMode.dark => "Sombre",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paramètres")),
      body: ListView(
        children: [
          SettingsSection(
            title: "Affichage",
            children: [
              ListTile(
                title: Row(
                  children: [
                    const Text("Thème"),
                    const SizedBox(width: 8),
                    Text(
                      _themeLabel,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(_themeIcon),
                  tooltip: "Thème : $_themeLabel (appuyer pour changer)",
                  onPressed: onToggleTheme,
                ),
              ),
            ],
          ),

          // Futures sections de paramètres : ajouter un autre
          // SettingsSection ici, sans modifier ce qui précède.
        ],
      ),
    );
  }
}
