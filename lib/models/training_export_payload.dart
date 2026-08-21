import 'training.dart';

/// Enveloppe historique v1 utilisée uniquement pour partager des séances.
class TrainingExportPayload {
  const TrainingExportPayload({
    required this.exportedAt,
    required this.trainings,
  });

  final DateTime exportedAt;
  final List<Training> trainings;

  Map<String, dynamic> toJson() => {
    'app': 'RepTimer',
    'exportFormatVersion': 1,
    'exportedAt': exportedAt.toIso8601String(),
    'trainings': trainings.map((training) => training.toJson()).toList(),
  };
}
