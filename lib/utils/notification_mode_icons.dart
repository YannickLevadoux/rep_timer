import 'package:flutter/material.dart';

import '../models/notification_mode.dart';

/// Résout un [NotificationMode] vers l'icône à afficher (même icône
/// utilisée dans les Paramètres et sur le contrôle rapide pendant une
/// séance, pour rester cohérent entre les deux). Séparé du modèle
/// [NotificationMode] pour ne pas lui faire porter de dépendance Flutter
/// — même principe que utils/exercise_icons.dart pour TrainingItem.
IconData iconForNotificationMode(NotificationMode mode) {
  return switch (mode) {
    NotificationMode.sound => Icons.notifications,
    NotificationMode.vibration => Icons.vibration,
    // Rond barré : la représentation la plus proche du panneau "sens
    // interdit" demandé par la spec, parmi les icônes Material standard.
    NotificationMode.none => Icons.do_not_disturb_on,
  };
}
