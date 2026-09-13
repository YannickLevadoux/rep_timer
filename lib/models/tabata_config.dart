// ignore_for_file: prefer_initializing_formals

import 'training_item.dart';

class TabataConfig {
  static const Duration defaultEffortDuration = Duration(seconds: 20);
  static const Duration defaultRestDuration = Duration(seconds: 10);

  TabataConfig({
    required int rounds,
    required List<TrainingItem> exercises,
    required Duration restDuration,
    this.finalRestDuration,
  }) : _rounds = rounds,
       exercises = List<TrainingItem>.of(exercises),
       _restItem = TrainingItem(
         type: ItemType.rest,
         name: 'Pause',
         duration: restDuration,
       );

  factory TabataConfig.defaults() => TabataConfig(
    rounds: 1,
    exercises: [
      TrainingItem(
        type: ItemType.exercise,
        name: 'Effort',
        duration: defaultEffortDuration,
      ),
    ],
    restDuration: defaultRestDuration,
  );

  int _rounds;
  List<TrainingItem> exercises;
  final TrainingItem _restItem;
  Duration? finalRestDuration;

  Duration get restDuration => _restItem.duration!;

  set restDuration(Duration value) => _restItem.duration = value;

  TrainingItem get legacyRestItem => _restItem;

  int get rounds => _rounds;

  set rounds(int value) {
    if (_rounds == 1 && value > 1 && finalRestDuration == null) {
      finalRestDuration = restDuration;
    }
    _rounds = value;
  }

  Duration? get effortDuration => exercises.firstOrNull?.duration;

  void setEffortDuration(Duration value) {
    for (final exercise in exercises) {
      exercise.duration = value;
    }
  }

  void resizeExercises(int count) {
    if (count < exercises.length) {
      exercises = exercises.take(count).toList();
      return;
    }
    if (exercises.isEmpty) return;
    while (exercises.length < count) {
      exercises.add(exercises.first.copyWith());
    }
  }

  void applySharedExerciseMetadata(TrainingItem value) {
    for (final exercise in exercises) {
      exercise
        ..name = value.name
        ..comment = value.comment
        ..iconName = value.iconName;
    }
  }

  TabataConfig copyWith({
    int? rounds,
    List<TrainingItem>? exercises,
    Duration? restDuration,
    Duration? finalRestDuration,
    bool clearFinalRestDuration = false,
  }) => TabataConfig(
    rounds: rounds ?? _rounds,
    exercises: (exercises ?? this.exercises)
        .map((exercise) => exercise.copyWith())
        .toList(),
    restDuration: restDuration ?? this.restDuration,
    finalRestDuration: clearFinalRestDuration
        ? null
        : finalRestDuration ?? this.finalRestDuration,
  );

  Map<String, dynamic> toJson() => {
    'rounds': rounds,
    'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    'restDurationSeconds': restDuration.inSeconds,
    'finalRestDurationSeconds': finalRestDuration?.inSeconds,
  };

  factory TabataConfig.fromJson(Map<String, dynamic> json) => TabataConfig(
    rounds: json['rounds'] as int,
    exercises: (json['exercises'] as List<dynamic>)
        .map((value) => TrainingItem.fromJson(value as Map<String, dynamic>))
        .toList(),
    restDuration: Duration(seconds: json['restDurationSeconds'] as int),
    finalRestDuration: json['finalRestDurationSeconds'] == null
        ? null
        : Duration(seconds: json['finalRestDurationSeconds'] as int),
  );
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
