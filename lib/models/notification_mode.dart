/// Mode de notification joué à la fin naturelle d'un exercice de type
/// Temps ou d'une pause. L'ordre des valeurs reflète l'ordre de
/// défilement au tap (Son -> Vibration -> Rien -> Son), aussi bien dans
/// les Paramètres que sur l'icône de contrôle rapide pendant une séance
/// (voir [next]).
enum NotificationMode {
  sound,
  vibration,
  none;

  /// Libellé affiché à l'utilisateur.
  String get label => switch (this) {
    NotificationMode.sound => "Son",
    NotificationMode.vibration => "Vibration",
    NotificationMode.none => "Rien",
  };

  /// Mode suivant dans le cycle de défilement (Son -> Vibration -> Rien
  /// -> Son), utilisé aussi bien par le réglage global (Paramètres) que
  /// par le contrôle rapide pendant une séance.
  NotificationMode get next =>
      NotificationMode.values[(index + 1) % NotificationMode.values.length];

  /// Résout une valeur persistée (nom d'enum) vers [NotificationMode],
  /// avec repli sur [NotificationMode.none] si absente ou inconnue —
  /// c'est aussi le comportement par défaut de l'application (voir
  /// AppSettingsStorage.defaultNotificationMode).
  static NotificationMode fromName(String? name) {
    return NotificationMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => NotificationMode.none,
    );
  }
}
