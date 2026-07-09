import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_history_entry.dart';

/// Sauvegarde locale de l'historique des séances effectuées (persistée en
/// JSON via SharedPreferences, même mécanisme que TrainingStorage).
class TrainingHistoryStorage {
  static const _storageKey = 'training_history';

  Future<List<TrainingHistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => TrainingHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Données corrompues/format incompatible : on repart d'une liste
      // vide plutôt que de planter l'appli.
      return [];
    }
  }

  Future<void> addEntry(TrainingHistoryEntry entry) async {
    final history = await loadHistory();
    history.add(entry);
    await _saveHistory(history);
  }

  Future<void> deleteEntry(String id) async {
    final history = await loadHistory();
    history.removeWhere((entry) => entry.id == id);
    await _saveHistory(history);
  }

  Future<void> _saveHistory(List<TrainingHistoryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}