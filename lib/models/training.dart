import 'exercise_group.dart';

class Training {
  String id;
  String name;
  List<ExerciseGroup> groups;
  DateTime createdAt;

  Training({
    required this.id,
    required this.name,
    required this.groups,
    required this.createdAt,
  });

  /// Duplique entièrement cette séance sous un nouveau [name] : nouvel
  /// identifiant pour la séance elle-même, et nouvel identifiant pour
  /// chacun de ses groupes (dont les items sont eux-mêmes recopiés en
  /// profondeur, voir ExerciseGroup.copyWith). La copie obtenue est donc
  /// totalement indépendante de l'original, qui n'est jamais modifié.
  ///
  /// [newId] est fourni par l'appelant (plutôt que généré ici) pour que
  /// ce modèle reste indépendant de tout mécanisme concret de génération
  /// d'identifiants ; passer par exemple `IdGenerator().next`.
  Training duplicate({required String name, required String Function() newId}) {
    return Training(
      id: newId(),
      name: name,
      createdAt: DateTime.now(),
      groups: groups.map((g) => g.copyWith(id: newId())).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'groups': groups.map((group) => group.toJson()).toList(),
  };

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      groups: (json['groups'] as List<dynamic>)
          .map((g) => ExerciseGroup.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }
}
