import 'package:flutter/material.dart';

import '../../services/session_notification_permission_service.dart';
import '../settings_section.dart';

class PermissionsSettingsSection extends StatelessWidget {
  final SessionNotificationPermissionStatus? permissionStatus;
  final VoidCallback onOpenPermissions;

  const PermissionsSettingsSection({
    super.key,
    required this.permissionStatus,
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
      title: 'Autorisations',
      children: [
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
