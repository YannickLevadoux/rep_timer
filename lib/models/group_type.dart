/// Type d'un groupe d'exercices.
enum GroupType {
  free,
  variableRepetitions;

  /// Libellé affiché à l'utilisateur (liste déroulante de l'écran
  /// d'édition, étiquette de synthèse...).
  String get label => switch (this) {
    GroupType.free => "Groupe libre",
    GroupType.variableRepetitions => "Groupe à répétitions variables",
  };

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
