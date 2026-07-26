import 'group_type.dart';
import 'training_item.dart';

class ExerciseGroup {
  final String id;

  String name;

  bool expanded;

  // Type du groupe (voir GroupType). Un seul type existe pour l'instant,
  // mais le champ est déjà persisté pour permettre l'ajout d'autres types
  // à l'avenir sans nouvelle migration de données.
  GroupType type;

  // Nombre de fois où le groupe doit être répété (par défaut 1)
  int rounds;

  List<TrainingItem> items;

  ExerciseGroup({
    required this.id,
    required this.name,
    this.expanded = true,
    this.type = GroupType.free,
    this.rounds = 1,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'rounds': rounds,
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory ExerciseGroup.fromJson(Map<String, dynamic> json) {
    return ExerciseGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      // Rétro-compatible : absent dans les données existantes -> free.
      type: GroupType.fromName(json['type'] as String?),
      rounds: json['rounds'] as int? ?? 1,
      items: (json['items'] as List<dynamic>)
          .map((e) => TrainingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
