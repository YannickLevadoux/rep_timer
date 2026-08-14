import 'amrap_checkpoint_state.dart';

/// Photographie de l'état d'une séance en cours d'exécution, persistée
/// régulièrement afin de pouvoir reprendre exactement où on en était même
/// si le processus de l'application est tué par le système (et pas
/// seulement mis en arrière-plan).
class SessionCheckpoint {
  final String trainingId;
  final int currentIndex;
  final List<bool> completed;
  final Duration globalElapsed;
  final Duration stepElapsed;
  final bool paused;
  final DateTime savedAt;

  // Temps réellement passé sur chaque étape déjà quittée (utilisé pour
  // l'historique détaillé) ; l'étape courante n'y figure pas encore tant
  // qu'on ne l'a pas quittée, voir stepElapsed pour son temps en cours.
  final List<Duration> stepActualDurations;
  final Map<int, AmrapCheckpointState> amrapStates;

  /// Alias rétro-compatible de l'état de l'occurrence courante.
  AmrapCheckpointState? get amrapState => amrapStates[currentIndex];

  SessionCheckpoint({
    required this.trainingId,
    required this.currentIndex,
    required List<bool> completed,
    required this.globalElapsed,
    required this.stepElapsed,
    required this.paused,
    required this.savedAt,
    required List<Duration> stepActualDurations,
    AmrapCheckpointState? amrapState,
    Map<int, AmrapCheckpointState> amrapStates = const {},
  }) : completed = List.unmodifiable(completed),
       stepActualDurations = List.unmodifiable(stepActualDurations),
       amrapStates = _copyAmrapStates(
         currentIndex: currentIndex,
         currentState: amrapState,
         states: amrapStates,
       );

  Map<String, dynamic> toJson() => {
    'trainingId': trainingId,
    'currentIndex': currentIndex,
    'completed': completed,
    'globalElapsedSeconds': globalElapsed.inSeconds,
    'stepElapsedSeconds': stepElapsed.inSeconds,
    'paused': paused,
    'savedAt': savedAt.toIso8601String(),
    'stepActualDurationsSeconds': stepActualDurations
        .map((d) => d.inSeconds)
        .toList(),
    'amrapState': amrapState?.toJson(),
    'amrapStates': amrapStates.map(
      (index, state) => MapEntry('$index', state.toJson()),
    ),
  };

  factory SessionCheckpoint.fromJson(Map<String, dynamic> json) {
    return SessionCheckpoint(
      trainingId: json['trainingId'] as String,
      currentIndex: json['currentIndex'] as int,
      completed: (json['completed'] as List<dynamic>)
          .map((e) => e as bool)
          .toList(),
      globalElapsed: Duration(seconds: json['globalElapsedSeconds'] as int),
      stepElapsed: Duration(seconds: json['stepElapsedSeconds'] as int),
      paused: json['paused'] as bool,
      savedAt: DateTime.parse(json['savedAt'] as String),
      // Rétro-compatible : absent dans un checkpoint sauvegardé par une
      // version antérieure de l'app.
      stepActualDurations:
          (json['stepActualDurationsSeconds'] as List<dynamic>?)
              ?.map((s) => Duration(seconds: s as int))
              .toList() ??
          const [],
      amrapState: json['amrapState'] == null
          ? null
          : AmrapCheckpointState.fromJson(
              json['amrapState'] as Map<String, dynamic>,
            ),
      amrapStates: _statesFromJson(json['amrapStates']),
    );
  }

  static Map<int, AmrapCheckpointState> _copyAmrapStates({
    required int currentIndex,
    required AmrapCheckpointState? currentState,
    required Map<int, AmrapCheckpointState> states,
  }) {
    final copy = <int, AmrapCheckpointState>{
      for (final entry in states.entries) entry.key: entry.value.copy(),
    };
    if (currentState != null) copy.putIfAbsent(currentIndex, currentState.copy);
    if (copy.keys.any((index) => index < 0)) {
      throw const FormatException("L'index AMRAP doit être positif.");
    }
    return Map.unmodifiable(copy);
  }

  static Map<int, AmrapCheckpointState> _statesFromJson(Object? value) {
    if (value == null) return const {};
    final json = value as Map<String, dynamic>;
    return json.map(
      (index, state) => MapEntry(
        int.parse(index),
        AmrapCheckpointState.fromJson(state as Map<String, dynamic>),
      ),
    );
  }
}
