import 'training_item.dart';

/// Snapshot d'une étape (exercice ou pause) telle qu'elle a réellement été
/// exécutée pendant une séance : nom, groupe d'appartenance, commentaire
/// et nombre de répétitions résolu au moment de l'exécution, ainsi que le
/// temps réellement passé (0 si jamais atteinte, partiel si interrompue).
class HistoryStepEntry {
  final String groupId;
  final String groupName;
  final ItemType itemType;
  final String itemName;
  final int? repetitions;
  final String? comment;
  final Duration actualDuration;
  final bool completed;

  HistoryStepEntry({
    required this.groupId,
    required this.groupName,
    required this.itemType,
    required this.itemName,
    this.repetitions,
    required this.comment,
    required this.actualDuration,
    required this.completed,
  });

  Map<String, dynamic> toJson() => {
    'groupId': groupId,
    'groupName': groupName,
    'itemType': itemType.name,
    'itemName': itemName,
    'repetitions': repetitions,
    'comment': comment,
    'actualDurationSeconds': actualDuration.inSeconds,
    'completed': completed,
  };

  factory HistoryStepEntry.fromJson(Map<String, dynamic> json) {
    return HistoryStepEntry(
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      itemType: ItemType.values.byName(json['itemType'] as String),
      itemName: json['itemName'] as String,
      // Rétro-compatible avec les historiques enregistrés avant l'ajout du
      // nombre de répétitions au snapshot de chaque étape.
      repetitions: json['repetitions'] as int?,
      comment: json['comment'] as String?,
      actualDuration: Duration(seconds: json['actualDurationSeconds'] as int),
      completed: json['completed'] as bool,
    );
  }
}
