/// Statut d'une séance enregistrée dans l'historique.
enum TrainingSessionStatus {
  completed, // Terminée : tous les exercices ont été effectués normalement
  incomplete, // Incomplète : la session a été arrêtée avant la fin (via "Terminer la session")
}

class TrainingHistoryEntry {
  final String id;
  final String trainingId;
  final String trainingName;
  final DateTime date;
  final Duration totalDuration;
  final TrainingSessionStatus status;

  TrainingHistoryEntry({
    required this.id,
    required this.trainingId,
    required this.trainingName,
    required this.date,
    required this.totalDuration,
    this.status = TrainingSessionStatus.completed,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'trainingId': trainingId,
        'trainingName': trainingName,
        'date': date.toIso8601String(),
        'totalDurationSeconds': totalDuration.inSeconds,
        'status': status.name,
      };

  factory TrainingHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TrainingHistoryEntry(
      id: json['id'] as String,
      trainingId: json['trainingId'] as String,
      trainingName: json['trainingName'] as String,
      date: DateTime.parse(json['date'] as String),
      totalDuration: Duration(seconds: json['totalDurationSeconds'] as int),
      // Rétro-compatible avec les entrées existantes qui n'ont pas ce champ.
      status: TrainingSessionStatus.values.byName(
        json['status'] as String? ?? TrainingSessionStatus.completed.name,
      ),
    );
  }
}