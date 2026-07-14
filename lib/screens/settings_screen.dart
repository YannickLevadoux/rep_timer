import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../services/training_export_service.dart';
import '../widgets/settings_section.dart';

/// Écran centralisant les paramètres de l'application, organisé en
/// sections pour faciliter l'ajout de nouveaux réglages à l'avenir.
class SettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TrainingExportService _exportService = TrainingExportService();

  // Désactive les actions Importer/Exporter pendant qu'une opération est
  // en cours, pour éviter tout double-déclenchement.
  bool _busy = false;

  // Logique de changement de thème réutilisée telle quelle depuis
  // l'écran d'accueil (même icône, même cycle Auto -> Clair -> Sombre).
  IconData get _themeIcon => switch (widget.themeMode) {
    ThemeMode.system => Icons.brightness_auto,
    ThemeMode.light => Icons.light_mode,
    ThemeMode.dark => Icons.dark_mode,
  };

  String get _themeLabel => switch (widget.themeMode) {
    ThemeMode.system => "Auto",
    ThemeMode.light => "Clair",
    ThemeMode.dark => "Sombre",
  };

  Future<void> _handleExport() async {
    setState(() => _busy = true);

    try {
      final filePath = await _exportService.exportToFile();

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: "Export des séances RepTimer",
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur lors de l'export : $e")));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    // Sélecteur annulé par l'utilisateur : rien à faire.
    if (result == null) return;

    final path = result.files.single.path;
    if (path == null) return;

    setState(() => _busy = true);

    try {
      final content = await File(path).readAsString();
      final importResult = await _exportService.importFromJsonString(content);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Import terminé : ${importResult.importedCount} séance(s) importée(s).",
          ),
        ),
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur lors de l'import : $e")));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
                  onPressed: widget.onToggleTheme,
                ),
              ),
            ],
          ),

          SettingsSection(
            title: "Import / Export",
            children: [
              ListTile(
                leading: const Icon(Icons.file_upload_outlined),
                title: const Text("Importer"),
                subtitle: const Text("Ajouter des séances depuis un fichier"),
                enabled: !_busy,
                onTap: _handleImport,
              ),
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text("Exporter"),
                subtitle: const Text(
                  "Partager toutes vos séances dans un fichier",
                ),
                enabled: !_busy,
                onTap: _handleExport,
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
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
