/// Type d'un groupe d'exercices. Un seul type existe pour l'instant
/// ("Groupe libre"), mais cette structure (enum + libellé associé) est
/// prévue pour accueillir de nouveaux types à l'avenir sans toucher au
/// reste du code : il suffira d'ajouter une valeur ici et de compléter le
/// switch de [label] (l'analyseur Dart signale tout switch non exhaustif
/// ailleurs dans le code, ce qui guide les futurs ajouts).
enum GroupType {
  free;

  /// Libellé affiché à l'utilisateur (liste déroulante de l'écran
  /// d'édition, étiquette de synthèse...).
  String get label => switch (this) {
    GroupType.free => "Groupe libre",
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
