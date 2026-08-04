import 'package:flutter/material.dart';

import '../../models/notification_mode.dart';
import '../../services/session_notification_permission_service.dart';
import '../../utils/notification_mode_icons.dart';
import '../settings_section.dart';

class DisplaySettingsSection extends StatelessWidget {
  final String themeLabel;
  final IconData themeIcon;
  final VoidCallback onToggleTheme;

  const DisplaySettingsSection({
    super.key,
    required this.themeLabel,
    required this.themeIcon,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Affichage',
      children: [
        ListTile(
          title: _TitleWithStatus(title: 'Thème', status: themeLabel),
          trailing: IconButton(
            icon: Icon(themeIcon),
            tooltip: 'Thème : $themeLabel (appuyer pour changer)',
            onPressed: onToggleTheme,
          ),
        ),
      ],
    );
  }
}

class EditingSettingsSection extends StatelessWidget {
  final bool prefillExerciseName;
  final ValueChanged<bool> onPrefillChanged;

  const EditingSettingsSection({
    super.key,
    required this.prefillExerciseName,
    required this.onPrefillChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Édition',
      children: [
        ListTile(
          title: const Text('Préremplir le nom des nouveaux exercices'),
          trailing: Switch(
            value: prefillExerciseName,
            onChanged: onPrefillChanged,
          ),
        ),
      ],
    );
  }
}

class NotificationSettingsSection extends StatelessWidget {
  final NotificationMode notificationMode;
  final SessionNotificationPermissionStatus? permissionStatus;
  final VoidCallback onCycleMode;
  final VoidCallback onOpenPermissions;

  const NotificationSettingsSection({
    super.key,
    required this.notificationMode,
    required this.permissionStatus,
    required this.onCycleMode,
    required this.onOpenPermissions,
  });

  String? get _permissionLabel => switch (permissionStatus) {
    SessionNotificationPermissionStatus.granted => 'Configurées',
    SessionNotificationPermissionStatus.denied ||
    SessionNotificationPermissionStatus.permanentlyDenied =>
      'Notifications désactivées',
    SessionNotificationPermissionStatus.unavailable || null => null,
  };

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Notifications',
      children: [
        ListTile(
          title: _TitleWithStatus(
            title: "Fin d'exercice",
            status: notificationMode.label,
          ),
          trailing: IconButton(
            icon: Icon(iconForNotificationMode(notificationMode)),
            tooltip:
                'Notifications : ${notificationMode.label} '
                '(appuyer pour changer)',
            onPressed: onCycleMode,
          ),
        ),
        Semantics(
          button: true,
          label: _permissionLabel == null
              ? 'Autorisations'
              : 'Autorisations, $_permissionLabel',
          child: ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text('Autorisations'),
            subtitle: _permissionLabel == null ? null : Text(_permissionLabel!),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenPermissions,
          ),
        ),
      ],
    );
  }
}

class TransferSettingsSection extends StatelessWidget {
  final bool busy;
  final VoidCallback onImport;
  final VoidCallback onExport;

  const TransferSettingsSection({
    super.key,
    required this.busy,
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
          subtitle: const Text('Ajouter des séances depuis un fichier'),
          enabled: !busy,
          onTap: onImport,
        ),
        ListTile(
          leading: const Icon(Icons.file_download_outlined),
          title: const Text('Exporter'),
          subtitle: const Text('Partager toutes vos séances dans un fichier'),
          enabled: !busy,
          onTap: onExport,
        ),
        if (busy)
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

class _TitleWithStatus extends StatelessWidget {
  final String title;
  final String status;

  const _TitleWithStatus({required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(title),
        Text(
          status,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      ],
    );
  }
}
