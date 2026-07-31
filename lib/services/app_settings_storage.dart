import 'package:shared_preferences/shared_preferences.dart';

/// Persistance des réglages globaux de l'application qui sont de simples
/// booléens (contrairement aux séances/historique/checkpoint, qui sont
/// des entités structurées passant par JsonListStorage/JsonObjectStorage
/// — voir json_prefs_storage.dart). Un simple drapeau ne justifie pas cet
/// encodage JSON : on utilise ici directement SharedPreferences.getBool/
/// setBool, qui reste le même mécanisme de stockage que le reste de
/// l'application.
class AppSettingsStorage {
  static const _prefillExerciseNameKey = 'prefill_exercise_name';

  /// Valeur par défaut : préremplissage activé, pour conserver le
  /// comportement historique de l'application sur toute installation qui
  /// n'a jamais modifié explicitement ce réglage.
  static const bool defaultPrefillExerciseName = true;

  /// Préremplissage du nom d'un nouvel exercice avec le nom du groupe
  /// parent. Lu à chaque ouverture d'écran/dialogue concerné (Paramètres,
  /// dialogue de réglages du GroupEditor) plutôt que mis en cache, afin
  /// que les deux interfaces restent toujours synchronisées sur la même
  /// préférence.
  Future<bool> loadPrefillExerciseName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefillExerciseNameKey) ?? defaultPrefillExerciseName;
  }

  Future<void> savePrefillExerciseName(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefillExerciseNameKey, value);
  }
}
