import 'package:flutter/material.dart';

import '../settings_section.dart';

class TransferSettingsSection extends StatelessWidget {
  final VoidCallback onImport;
  final VoidCallback onExport;

  const TransferSettingsSection({
    super.key,
    required this.onImport,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Import / Export',
      children: [
        ListTile(
          leading: const Icon(Icons.file_upload_outlined),
          title: const Text('Importer'),
          subtitle: const Text('Importer ou restaurer depuis un fichier'),
          onTap: onImport,
        ),
        ListTile(
          leading: const Icon(Icons.file_download_outlined),
          title: const Text('Exporter'),
          subtitle: const Text('Partager une sauvegarde complète'),
          onTap: onExport,
        ),
      ],
    );
  }
}

class AboutSettingsSection extends StatelessWidget {
  final VoidCallback onOpenAbout;

  const AboutSettingsSection({super.key, required this.onOpenAbout});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'À propos',
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('À propos'),
          onTap: onOpenAbout,
        ),
      ],
    );
  }
}
