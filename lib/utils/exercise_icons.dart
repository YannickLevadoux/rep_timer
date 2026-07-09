import 'package:flutter/material.dart';

/// Icône par défaut pour tout exercice sans icône personnalisée choisie
/// (nouveaux exercices comme exercices existants créés avant cette
/// fonctionnalité).
const String defaultExerciseIconName = 'fitness_center';

/// Liste prédéfinie et exclusive des icônes disponibles pour personnaliser
/// un exercice. La clé (String) est ce qui est réellement persisté dans
/// TrainingItem.iconName, car IconData lui-même n'est pas sérialisable en
/// JSON de façon stable.
const Map<String, IconData> availableExerciseIcons = {
  'fitness_center': Icons.fitness_center,
  'rowing': Icons.rowing,
  'directions_run': Icons.directions_run,
  'directions_bike': Icons.directions_bike,
  'directions_walk': Icons.directions_walk,
  'monitor_heart': Icons.monitor_heart,
  'sports': Icons.sports,
  'sports_gymnastics': Icons.sports_gymnastics,
  'sports_martial_arts': Icons.sports_martial_arts,
  'sports_score': Icons.sports_score,
  'accessibility_new': Icons.accessibility_new,
  'self_improvement': Icons.self_improvement,
  'local_fire_department': Icons.local_fire_department,
  'leaderboard': Icons.leaderboard,
  'emoji_events': Icons.emoji_events,
  'star': Icons.star,
  'bolt': Icons.bolt,
  'flag': Icons.flag,
  'monitor_weight': Icons.monitor_weight,
};

/// Résout le nom d'icône persisté vers l'IconData correspondante, avec
/// repli sur l'icône par défaut si le nom est absent ou inconnu (donnée
/// corrompue, ancienne version de l'app...).
IconData iconForExercise(String? iconName) {
  return availableExerciseIcons[iconName] ??
      availableExerciseIcons[defaultExerciseIconName]!;
}