import 'package:flutter/material.dart';

import '../../models/notification_mode.dart';
import '../../utils/notification_mode_icons.dart';
import '../settings_section.dart';

class DisplaySettingsSection extends StatelessWidget {
  final ThemeMode themeMode;
  final VoidCallback? onToggleTheme;

  const DisplaySettingsSection({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  IconData get _themeIcon => switch (themeMode) {
    ThemeMode.system => Icons.brightness_auto,
    ThemeMode.light => Icons.light_mode,
    ThemeMode.dark => Icons.dark_mode,
  };

  String get _themeLabel => switch (themeMode) {
    ThemeMode.system => 'Système',
    ThemeMode.light => 'Clair',
    ThemeMode.dark => 'Sombre',
  };

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Affichage',
      children: [
        ListTile(
          title: _TitleWithStatus(title: 'Thème', status: _themeLabel),
          trailing: IconButton(
            icon: Icon(_themeIcon),
            tooltip: 'Thème : $_themeLabel (appuyer pour changer)',
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
  final VoidCallback onCycleMode;

  const NotificationSettingsSection({
    super.key,
    required this.notificationMode,
    required this.onCycleMode,
  });

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
