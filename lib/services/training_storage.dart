import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/training.dart';

/// Sauvegarde locale des séances (persistées en JSON via SharedPreferences).
/// Fonctionne directement sur Android/iOS/desktop, sans configuration native.
class TrainingStorage {
  static const _storageKey = 'trainings';

  Future<List<Training>> loadTrainings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Training.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Données corrompues/format incompatible : on repart d'une liste
      // vide plutôt que de planter l'appli.
      return [];
    }
  }

  Future<void> saveTrainings(List<Training> trainings) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(trainings.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> addOrUpdateTraining(Training training) async {
    final trainings = await loadTrainings();
    final index = trainings.indexWhere((t) => t.id == training.id);

    if (index >= 0) {
      trainings[index] = training;
    } else {
      trainings.add(training);
    }

    await saveTrainings(trainings);
  }

  Future<void> deleteTraining(String id) async {
    final trainings = await loadTrainings();
    trainings.removeWhere((t) => t.id == id);
    await saveTrainings(trainings);
  }
}
