import 'group_type.dart';
import 'training_item.dart';

class ExerciseGroup {
  static const Duration defaultTabataEffort = Duration(seconds: 20);
  static const Duration defaultTabataRest = Duration(seconds: 10);
  static const Duration defaultAmrapDuration = Duration(minutes: 2);
  static const Duration defaultEmomInterval = Duration(minutes: 1);
  static const Duration defaultPostGroupRest = Duration(minutes: 1);

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

  /// Remplace la dernière pause Tabata lorsqu'un autre groupe suit.
  Duration? finalRestDuration;

  /// Ajoute une récupération après un AMRAP ou un EMOM si un groupe suit.
  Duration? postGroupRestDuration;

  ExerciseGroup({
    required this.id,
    required this.name,
    this.type = GroupType.free,
    this.expanded = true,
    this.rounds = 1,
    List<int>? repetitionSequence,
    required this.items,
    this.finalRestDuration,
    this.postGroupRestDuration,
  }) : repetitionSequence = List<int>.of(repetitionSequence ?? const []);

  factory ExerciseGroup.tabata({required String id}) => ExerciseGroup(
    id: id,
    name: 'Tabata',
    type: GroupType.tabata,
    items: [
      TrainingItem(
        type: ItemType.exercise,
        name: 'Effort',
        duration: defaultTabataEffort,
      ),
      TrainingItem(
        type: ItemType.rest,
        name: 'Pause',
        duration: defaultTabataRest,
      ),
    ],
  );

  factory ExerciseGroup.amrap({required String id}) => ExerciseGroup(
    id: id,
    name: 'AMRAP',
    type: GroupType.amrap,
    items: [
      TrainingItem(
        type: ItemType.exercise,
        name: 'Effort',
        duration: defaultAmrapDuration,
      ),
    ],
  );

  factory ExerciseGroup.emom({required String id}) => ExerciseGroup(
    id: id,
    name: 'EMOM',
    type: GroupType.emom,
    rounds: 10,
    items: [
      TrainingItem(
        type: ItemType.exercise,
        name: 'Effort',
        duration: defaultEmomInterval,
      ),
    ],
  );

  /// Nombre de tours réellement développés lors de l'exécution.
  int get executedRounds => switch (type) {
    GroupType.variableRepetitions => repetitionSequence.length,
    GroupType.amrap => 1,
    _ => rounds,
  };

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
    Duration? finalRestDuration,
    Duration? postGroupRestDuration,
    bool clearFinalRestDuration = false,
    bool clearPostGroupRestDuration = false,
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
      finalRestDuration: clearFinalRestDuration
          ? null
          : finalRestDuration ?? this.finalRestDuration,
      postGroupRestDuration: clearPostGroupRestDuration
          ? null
          : postGroupRestDuration ?? this.postGroupRestDuration,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'rounds': rounds,
    'repetitionSequence': repetitionSequence,
    'finalRestDurationSeconds': finalRestDuration?.inSeconds,
    'postGroupRestDurationSeconds': postGroupRestDuration?.inSeconds,
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
      finalRestDuration: _durationFromSeconds(json['finalRestDurationSeconds']),
      postGroupRestDuration: _durationFromSeconds(
        json['postGroupRestDurationSeconds'],
      ),
      items: (json['items'] as List<dynamic>)
          .map((e) => TrainingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static Duration? _durationFromSeconds(Object? value) =>
      value == null ? null : Duration(seconds: value as int);
}
