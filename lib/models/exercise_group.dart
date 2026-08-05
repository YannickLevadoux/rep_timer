import 'group_type.dart';
import 'training_item.dart';

class ExerciseGroup {
  final String id;

  String name;

  GroupType type;

  bool expanded;

  // Nombre de fois où le groupe doit être répété (par défaut 1)
  int rounds;

  /// Valeurs finales appliquées, tour par tour, aux exercices en mode
  /// répétitions d'un groupe [GroupType.variableRepetitions]. Conservée même
  /// lorsque le groupe repasse en mode libre afin que le changement de type
  /// reste entièrement réversible.
  List<int> repetitionSequence;

  List<TrainingItem> items;

  ExerciseGroup({
    required this.id,
    required this.name,
    this.type = GroupType.free,
    this.expanded = true,
    this.rounds = 1,
    List<int>? repetitionSequence,
    required this.items,
  }) : repetitionSequence = List<int>.of(repetitionSequence ?? const []);

  /// Nombre de tours réellement développés lors de l'exécution.
  int get executedRounds => type == GroupType.variableRepetitions
      ? repetitionSequence.length
      : rounds;

  /// Copie profonde de ce groupe : [items] est systématiquement recopié
  /// (chaque item via [TrainingItem.copyWith]), jamais partagé avec
  /// l'original — y compris si [items] n'est pas explicitement fourni.
  /// Sans cela, une modification faite sur la copie (ex : dans l'écran
  /// d'édition, avant "Enregistrer") se répercuterait silencieusement sur
  /// l'instance d'origine.
  ///
  /// Les autres champs omis reprennent la valeur actuelle. [id] n'est
  /// changé que si explicitement fourni : une édition en cours veut
  /// conserver le même id (remplacement à l'enregistrement), tandis
  /// qu'un import veut au contraire toujours en générer un nouveau.
  ExerciseGroup copyWith({
    String? id,
    String? name,
    GroupType? type,
    bool? expanded,
    int? rounds,
    List<int>? repetitionSequence,
    List<TrainingItem>? items,
  }) {
    return ExerciseGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      expanded: expanded ?? this.expanded,
      rounds: rounds ?? this.rounds,
      repetitionSequence: List<int>.of(
        repetitionSequence ?? this.repetitionSequence,
      ),
      items: (items ?? this.items).map((item) => item.copyWith()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'rounds': rounds,
    'repetitionSequence': repetitionSequence,
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory ExerciseGroup.fromJson(Map<String, dynamic> json) {
    return ExerciseGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      type: GroupType.fromName(json['type'] as String?),
      rounds: json['rounds'] as int? ?? 1,
      repetitionSequence:
          (json['repetitionSequence'] as List<dynamic>?)
              ?.map((value) => value as int)
              .toList() ??
          const [],
      items: (json['items'] as List<dynamic>)
          .map((e) => TrainingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
