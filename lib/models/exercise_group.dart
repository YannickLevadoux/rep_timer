// ignore_for_file: prefer_initializing_formals

import 'exercise_group_json.dart';
import 'group_type.dart';
import 'tabata_config.dart';
import 'training_item.dart';

class ExerciseGroup {
  static const Duration defaultTabataEffort =
      TabataConfig.defaultEffortDuration;
  static const Duration defaultTabataRest = TabataConfig.defaultRestDuration;
  static const Duration defaultAmrapDuration = Duration(minutes: 2);
  static const Duration defaultEmomInterval = Duration(minutes: 1);
  static const Duration defaultPostGroupRest = Duration(minutes: 1);

  final String id;
  String name;
  GroupType type;
  bool expanded;

  int _rounds;

  /// Valeurs appliquées tour par tour aux groupes à répétitions variables.
  List<int> repetitionSequence;

  List<TrainingItem> items;

  final TabataConfig? tabataConfig;

  /// Remplace la dernière pause Tabata lorsqu'un autre groupe suit.
  Duration? _finalRestDuration;

  /// Ajoute une récupération après un AMRAP ou un EMOM si un groupe suit.
  Duration? postGroupRestDuration;

  ExerciseGroup({
    required this.id,
    required this.name,
    this.type = GroupType.free,
    this.expanded = true,
    int rounds = 1,
    List<int>? repetitionSequence,
    required this.items,
    Duration? finalRestDuration,
    this.postGroupRestDuration,
    this.tabataConfig,
  }) : _rounds = rounds,
       _finalRestDuration = finalRestDuration,
       repetitionSequence = List<int>.of(repetitionSequence ?? const []);

  factory ExerciseGroup.tabata({required String id}) =>
      ExerciseGroup.withTabataConfig(
        id: id,
        name: 'Tabata',
        config: TabataConfig.defaults(),
      );

  factory ExerciseGroup.withTabataConfig({
    required String id,
    required String name,
    required TabataConfig config,
    bool expanded = true,
    List<int>? repetitionSequence,
    Duration? postGroupRestDuration,
  }) {
    final exercises = config.exercises;
    return ExerciseGroup(
      id: id,
      name: name,
      type: GroupType.tabata,
      expanded: expanded,
      rounds: exercises.length,
      repetitionSequence: repetitionSequence,
      items: exercises.isEmpty ? [] : [exercises.first, config.legacyRestItem],
      finalRestDuration: config.finalRestDuration,
      postGroupRestDuration: postGroupRestDuration,
      tabataConfig: config,
    );
  }

  int get rounds => _rounds;

  set rounds(int value) {
    _rounds = value;
    if (type == GroupType.tabata && tabataConfig != null) {
      tabataConfig!.resizeExercises(value);
    }
  }

  Duration? get finalRestDuration =>
      type == GroupType.tabata && tabataConfig != null
      ? tabataConfig!.finalRestDuration
      : _finalRestDuration;

  set finalRestDuration(Duration? value) {
    if (type == GroupType.tabata && tabataConfig != null) {
      tabataConfig!.finalRestDuration = value;
    } else {
      _finalRestDuration = value;
    }
  }

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

  /// Copie profonde, y compris les exercices de la configuration Tabata.
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
    TabataConfig? tabataConfig,
  }) {
    final copiedTabata = (tabataConfig ?? this.tabataConfig)?.copyWith(
      finalRestDuration: finalRestDuration,
      clearFinalRestDuration: clearFinalRestDuration,
    );
    if (rounds != null) copiedTabata?.resizeExercises(rounds);
    if ((type ?? this.type) == GroupType.tabata && copiedTabata != null) {
      return ExerciseGroup.withTabataConfig(
        id: id ?? this.id,
        name: name ?? this.name,
        config: copiedTabata,
        expanded: expanded ?? this.expanded,
        repetitionSequence: repetitionSequence ?? this.repetitionSequence,
        postGroupRestDuration: clearPostGroupRestDuration
            ? null
            : postGroupRestDuration ?? this.postGroupRestDuration,
      );
    }
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
      tabataConfig: copiedTabata,
    );
  }

  Map<String, dynamic> toJson() => exerciseGroupToJson(this);

  factory ExerciseGroup.fromJson(Map<String, dynamic> json) =>
      exerciseGroupFromJson(json);
}
