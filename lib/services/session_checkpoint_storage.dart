import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_checkpoint.dart';

/// Sauvegarde locale du checkpoint de la séance actuellement en cours
/// (une seule séance active à la fois dans l'application, donc une seule
/// clé). Même mécanisme JSON/SharedPreferences que le reste de l'app.
class SessionCheckpointStorage {
  static const _storageKey = 'session_checkpoint';

  Future<void> saveCheckpoint(SessionCheckpoint checkpoint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(checkpoint.toJson()));
  }

  Future<SessionCheckpoint?> loadCheckpoint() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) return null;

    try {
      return SessionCheckpoint.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      // Checkpoint corrompu/format incompatible : on l'ignore plutôt que
      // de planter l'appli.
      return null;
    }
  }

  Future<void> clearCheckpoint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}