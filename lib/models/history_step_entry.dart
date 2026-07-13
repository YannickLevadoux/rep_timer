import 'training_item.dart';

/// Snapshot d'une étape (exercice ou pause) telle qu'elle a réellement été
/// exécutée pendant une séance : nom, groupe d'appartenance, commentaire
/// au moment de l'exécution, et temps réellement passé (0 si jamais
/// atteinte, partiel si interrompue).
class HistoryStepEntry {
  final String groupId;
  final String groupName;
  final ItemType itemType;
  final String itemName;
  final String? comment;
  final Duration actualDuration;
  final bool completed;

  HistoryStepEntry({
    required this.groupId,
    required this.groupName,
    required this.itemType,
    required this.itemName,
    required this.comment,
    required this.actualDuration,
    required this.completed,
  });

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'groupName': groupName,
        'itemType': itemType.name,
        'itemName': itemName,
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
      comment: json['comment'] as String?,
      actualDuration: Duration(seconds: json['actualDurationSeconds'] as int),
      completed: json['completed'] as bool,
    );
  }
}