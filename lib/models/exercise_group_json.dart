import 'exercise_group.dart';
import 'group_type.dart';
import 'tabata_config.dart';
import 'training_item.dart';

Map<String, dynamic> exerciseGroupToJson(ExerciseGroup group) {
  final common = <String, dynamic>{
    'id': group.id,
    'name': group.name,
    'type': group.type.name,
    'repetitionSequence': group.repetitionSequence,
    'postGroupRestDurationSeconds': group.postGroupRestDuration?.inSeconds,
  };
  if (group.type == GroupType.tabata) {
    return {...common, 'tabata': group.tabataConfig?.toJson()};
  }
  return {
    ...common,
    'rounds': group.rounds,
    'finalRestDurationSeconds': group.finalRestDuration?.inSeconds,
    'items': group.items.map((item) => item.toJson()).toList(),
  };
}

ExerciseGroup exerciseGroupFromJson(Map<String, dynamic> json) {
  final type = GroupType.fromName(json['type'] as String?);
  if (type == GroupType.tabata) {
    return json.containsKey('tabata')
        ? _fromCurrentTabata(json)
        : _fromLegacyTabata(json);
  }
  if (json.containsKey('tabata')) throw const FormatException();
  return ExerciseGroup(
    id: json['id'] as String,
    name: json['name'] as String,
    type: type,
    rounds: json['rounds'] as int? ?? 1,
    repetitionSequence: _sequence(json),
    finalRestDuration: _duration(json['finalRestDurationSeconds']),
    postGroupRestDuration: _duration(json['postGroupRestDurationSeconds']),
    items: _items(json['items']),
  );
}

ExerciseGroup _fromCurrentTabata(Map<String, dynamic> json) {
  final rawConfig = json['tabata'];
  if (rawConfig is! Map<String, dynamic>) throw const FormatException();
  final config = TabataConfig.fromJson(rawConfig);
  return ExerciseGroup.withTabataConfig(
    id: json['id'] as String,
    name: json['name'] as String,
    config: config,
    repetitionSequence: _sequence(json),
    postGroupRestDuration: _duration(json['postGroupRestDurationSeconds']),
  );
}

ExerciseGroup _fromLegacyTabata(Map<String, dynamic> json) {
  final cycles = json['rounds'];
  final legacyItems = _items(json['items']);
  if (cycles is! int || cycles < 1 || cycles > 999 || legacyItems.length != 2) {
    throw const FormatException();
  }
  final effort = legacyItems.first;
  final rest = legacyItems.last;
  if (!_isTimed(effort, ItemType.exercise) || !_isTimed(rest, ItemType.rest)) {
    throw const FormatException();
  }
  return ExerciseGroup.withTabataConfig(
    id: json['id'] as String,
    name: json['name'] as String,
    config: TabataConfig(
      rounds: 1,
      exercises: List.generate(cycles, (_) => effort.copyWith()),
      restDuration: rest.duration!,
      finalRestDuration: _duration(json['finalRestDurationSeconds']),
    ),
    repetitionSequence: _sequence(json),
    postGroupRestDuration: _duration(json['postGroupRestDurationSeconds']),
  );
}

List<int> _sequence(Map<String, dynamic> json) =>
    (json['repetitionSequence'] as List<dynamic>?)
        ?.map((value) => value as int)
        .toList() ??
    const [];

List<TrainingItem> _items(Object? value) => (value as List<dynamic>)
    .map((item) => TrainingItem.fromJson(item as Map<String, dynamic>))
    .toList();

Duration? _duration(Object? value) =>
    value == null ? null : Duration(seconds: value as int);

bool _isTimed(TrainingItem item, ItemType type) =>
    item.type == type &&
    item.duration != null &&
    item.repetitions == null &&
    !item.isFreeDuration;
