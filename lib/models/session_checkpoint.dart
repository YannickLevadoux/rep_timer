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

  SessionCheckpoint({
    required this.trainingId,
    required this.currentIndex,
    required this.completed,
    required this.globalElapsed,
    required this.stepElapsed,
    required this.paused,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'trainingId': trainingId,
        'currentIndex': currentIndex,
        'completed': completed,
        'globalElapsedSeconds': globalElapsed.inSeconds,
        'stepElapsedSeconds': stepElapsed.inSeconds,
        'paused': paused,
        'savedAt': savedAt.toIso8601String(),
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
    );
  }
}