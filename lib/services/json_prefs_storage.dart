import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistance générique d'une liste d'objets en JSON via
/// SharedPreferences. Factorise le mécanisme commun à tous les services
/// de stockage de l'application (encode/decode JSON, tolérance aux
/// données corrompues/format incompatible).
class JsonListStorage<T> {
  JsonListStorage({
    required String storageKey,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T value) toJson,
  }) : _storageKey = storageKey,
       _fromJson = fromJson,
       _toJson = toJson;

  final String _storageKey;
  final T Function(Map<String, dynamic> json) _fromJson;
  final Map<String, dynamic> Function(T value) _toJson;

  Future<List<T>> loadList() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Données corrompues/format incompatible : on repart d'une liste
      // vide plutôt que de planter l'appli.
      return [];
    }
  }

  Future<void> saveList(List<T> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map(_toJson).toList());
    await prefs.setString(_storageKey, encoded);
  }
}

/// Persistance générique d'un objet unique (au plus un par clé) en JSON
/// via SharedPreferences. Même mécanisme que [JsonListStorage], pour les
/// cas où une seule instance est conservée (ex : checkpoint de la séance
/// en cours).
class JsonObjectStorage<T> {
  JsonObjectStorage({
    required String storageKey,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T value) toJson,
  }) : _storageKey = storageKey,
       _fromJson = fromJson,
       _toJson = toJson;

  final String _storageKey;
  final T Function(Map<String, dynamic> json) _fromJson;
  final Map<String, dynamic> Function(T value) _toJson;

  Future<void> save(T value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_toJson(value)));
  }

  Future<T?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) return null;

    try {
      return _fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Donnée corrompue/format incompatible : on l'ignore plutôt que de
      // planter l'appli.
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
