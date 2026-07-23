import 'training_item.dart';

enum ExerciseGroupType { free }

class ExerciseGroup {
  final String id;

  String name;

  ExerciseGroupType type;

  // Nombre de fois où le groupe doit être répété (par défaut 1)
  int rounds;

  List<TrainingItem> items;

  ExerciseGroup({
    required this.id,
    required this.name,
    this.type = ExerciseGroupType.free,
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
      type: ExerciseGroupType.values.byName(
        json['type'] as String? ?? ExerciseGroupType.free.name,
      ),
      rounds: json['rounds'] as int? ?? 1,
      items: (json['items'] as List<dynamic>)
          .map((e) => TrainingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
