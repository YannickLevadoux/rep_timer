/// Type d'un groupe d'exercices.
enum GroupType {
  free,
  variableRepetitions,
  tabata,
  amrap,
  emom;

  /// Libellé affiché à l'utilisateur (liste déroulante de l'écran
  /// d'édition, étiquette de synthèse...).
  String get label => switch (this) {
    GroupType.free => "Groupe libre",
    GroupType.variableRepetitions => "Groupe à répétitions variables",
    GroupType.tabata => 'Tabata',
    GroupType.amrap => 'AMRAP',
    GroupType.emom => 'EMOM',
  };

  String get shortLabel => switch (this) {
    GroupType.free => 'Libre',
    GroupType.variableRepetitions => 'Variables',
    _ => label,
  };

  String get description => switch (this) {
    GroupType.free => 'Enchaînez librement exercices et pauses.',
    GroupType.variableRepetitions =>
      'Définissez les répétitions de chaque tour.',
    GroupType.tabata => 'Alternez un effort et une pause sur plusieurs cycles.',
    GroupType.amrap => 'Réalisez un maximum de tours pendant la durée choisie.',
    GroupType.emom => 'Redémarrez l’exercice au début de chaque minute.',
  };

  bool get isTimed =>
      this == GroupType.tabata ||
      this == GroupType.amrap ||
      this == GroupType.emom;

  /// Résout une valeur persistée (nom d'enum) vers [GroupType], avec repli
  /// sur [GroupType.free] si absente ou inconnue (donnée corrompue,
  /// séance créée avant l'ajout de ce champ, ou export provenant d'une
  /// version plus récente de l'app introduisant un type inconnu ici).
  static GroupType fromName(String? name) {
    return GroupType.values.firstWhere(
      (t) => t.name == name,
      orElse: () => GroupType.free,
    );
  }
}
