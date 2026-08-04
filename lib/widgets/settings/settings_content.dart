import 'package:flutter/material.dart';

import '../../models/notification_mode.dart';
import '../../services/session_notification_permission_service.dart';
import 'general_settings_sections.dart';
import 'permissions_settings_section.dart';
import 'transfer_settings_sections.dart';

class SettingsContent extends StatelessWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final bool prefillExerciseName;
  final ValueChanged<bool> onPrefillChanged;
  final NotificationMode notificationMode;
  final VoidCallback onCycleNotificationMode;
  final bool busy;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final SessionNotificationPermissionStatus? permissionStatus;
  final VoidCallback onOpenPermissions;
  final VoidCallback onOpenAbout;

  const SettingsContent({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    required this.prefillExerciseName,
    required this.onPrefillChanged,
    required this.notificationMode,
    required this.onCycleNotificationMode,
    required this.busy,
    required this.onImport,
    required this.onExport,
    required this.permissionStatus,
    required this.onOpenPermissions,
    required this.onOpenAbout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          DisplaySettingsSection(
            themeMode: themeMode,
            onToggleTheme: onToggleTheme,
          ),
          EditingSettingsSection(
            prefillExerciseName: prefillExerciseName,
            onPrefillChanged: onPrefillChanged,
          ),
          NotificationSettingsSection(
            notificationMode: notificationMode,
            onCycleMode: onCycleNotificationMode,
          ),
          TransferSettingsSection(
            busy: busy,
            onImport: onImport,
            onExport: onExport,
          ),
          PermissionsSettingsSection(
            permissionStatus: permissionStatus,
            onOpenPermissions: onOpenPermissions,
          ),
          AboutSettingsSection(onOpenAbout: onOpenAbout),
        ],
      ),
    );
  }
}
