import 'exercise_group.dart';

class Training {
  String id;
  String name;
  List<ExerciseGroup> groups;
  DateTime createdAt;

  Training({
    required this.id,
    required this.name,
    required this.groups,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'groups': groups.map((group) => group.toJson()).toList(),
      };

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      groups: (json['groups'] as List<dynamic>)
          .map((g) => ExerciseGroup.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }
}