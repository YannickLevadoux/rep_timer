import 'package:flutter/material.dart';

import 'notification_mode.dart';

/// Les préférences utilisateur incluses dans le format de sauvegarde v2.
@immutable
class ExportableAppSettings {
  const ExportableAppSettings({
    required this.themeMode,
    required this.prefillExerciseName,
    required this.notificationMode,
  });

  final ThemeMode themeMode;
  final bool prefillExerciseName;
  final NotificationMode notificationMode;
}
