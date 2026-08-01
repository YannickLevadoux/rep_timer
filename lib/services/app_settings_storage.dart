import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_mode.dart';

/// Persistance des réglages globaux de l'application qui sont de simples
/// booléens/valeurs scalaires (contrairement aux séances/historique/
/// checkpoint, qui sont des entités structurées passant par
/// JsonListStorage/JsonObjectStorage — voir json_prefs_storage.dart). Un
/// simple drapeau ou une valeur d'enum ne justifient pas cet encodage
/// JSON : on utilise ici directement SharedPreferences.getBool/setBool
/// et getString/setString, qui restent le même mécanisme de stockage que
/// le reste de l'application.
class AppSettingsStorage {
  static const _prefillExerciseNameKey = 'prefill_exercise_name';
  static const _notificationModeKey = 'notification_mode';

  /// Valeur par défaut : préremplissage activé, pour conserver le
  /// comportement historique de l'application sur toute installation qui
  /// n'a jamais modifié explicitement ce réglage.
  static const bool defaultPrefillExerciseName = true;

  /// Valeur par défaut : aucune notification, conformément à la spec
  /// ("Rien" est le comportement par défaut de l'application).
  static const NotificationMode defaultNotificationMode = NotificationMode.none;

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

  /// Configuration globale des notifications de fin d'exercice/pause :
  /// comportement par défaut de toute nouvelle séance (voir
  /// SessionController, qui l'initialise une fois au démarrage puis
  /// n'utilise plus que sa propre configuration de session).
  Future<NotificationMode> loadNotificationMode() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationMode.fromName(prefs.getString(_notificationModeKey));
  }

  Future<void> saveNotificationMode(NotificationMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationModeKey, mode.name);
  }
}
