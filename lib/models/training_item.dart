enum ItemType { exercise, rest }

class TrainingItem {
  ItemType type;

  String name;

  int? repetitions;

  Duration? duration;

  // Exercice de type "Durée libre" : ni durée ni répétitions définies à
  // l'avance, l'utilisateur décide lui-même de la fin de l'exercice.
  // Champ explicite (plutôt que de déduire ce mode de duration/repetitions
  // tous deux null) pour lever toute ambiguïté avec un champ répétitions
  // simplement laissé vide.
  bool isFreeDuration;

  // Note personnalisée associée à l'exercice (poids, intensité...).
  // Optionnelle, propre à chaque exercice.
  String? comment;

  // Nom de l'icône personnalisée (clé de availableExerciseIcons), propre à
  // chaque exercice. Null = icône par défaut (fitness_center).
  String? iconName;

  TrainingItem({
    required this.type,
    required this.name,
    this.repetitions,
    this.duration,
    this.isFreeDuration = false,
    this.comment,
    this.iconName,
  });

  /// Copie profonde de cet item : aucun champ n'est partagé avec
  /// l'original (utile car [ExerciseGroup] recopie ses items à chaque
  /// [ExerciseGroup.copyWith], pour éviter qu'une édition en cours ne
  /// modifie l'instance d'origine avant sauvegarde).
  ///
  /// Comme tout `copyWith` classique, un paramètre omis reprend la valeur
  /// actuelle : il n'est donc pas possible de remettre explicitement un
  /// champ nullable à `null` via cette méthode (non nécessaire pour les
  /// usages actuels, purement des copies à l'identique).
  TrainingItem copyWith({
    ItemType? type,
    String? name,
    int? repetitions,
    Duration? duration,
    bool? isFreeDuration,
    String? comment,
    String? iconName,
  }) {
    return TrainingItem(
      type: type ?? this.type,
      name: name ?? this.name,
      repetitions: repetitions ?? this.repetitions,
      duration: duration ?? this.duration,
      isFreeDuration: isFreeDuration ?? this.isFreeDuration,
      comment: comment ?? this.comment,
      iconName: iconName ?? this.iconName,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'name': name,
    'repetitions': repetitions,
    'durationSeconds': duration?.inSeconds,
    'isFreeDuration': isFreeDuration,
    'comment': comment,
    'iconName': iconName,
  };

  factory TrainingItem.fromJson(Map<String, dynamic> json) {
    return TrainingItem(
      type: ItemType.values.byName(json['type'] as String),
      name: json['name'] as String,
      repetitions: json['repetitions'] as int?,
      duration: json['durationSeconds'] != null
          ? Duration(seconds: json['durationSeconds'] as int)
          : null,
      // Rétro-compatible : absent dans les données existantes -> false.
      isFreeDuration: json['isFreeDuration'] as bool? ?? false,
      comment: json['comment'] as String?,
      iconName: json['iconName'] as String?,
    );
  }
}
