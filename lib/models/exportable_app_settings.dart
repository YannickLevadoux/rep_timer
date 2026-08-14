import 'package:flutter/material.dart';

import 'notification_mode.dart';

/// Les préférences utilisateur incluses dans le format de sauvegarde courant.
@immutable
class ExportableAppSettings {
  const ExportableAppSettings({
    required this.themeMode,
    required this.prefillExerciseName,
    required this.notificationMode,
    this.preSessionCountdownSeconds = 0,
  });

  final ThemeMode themeMode;
  final bool prefillExerciseName;
  final NotificationMode notificationMode;
  final int preSessionCountdownSeconds;
}
