import 'package:flutter/material.dart';
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
abstract interface class SessionPermissionPromptStorage {
  Future<bool> loadSessionNotificationExplanationPresented();
  Future<void> saveSessionNotificationExplanationPresented(bool value);
}

/// Les préférences utilisateur incluses dans le format de sauvegarde v2.
///
/// Ce regroupement évite aux futurs services d'export/import de connaître les
/// clés de [SharedPreferences] ou de dupliquer les conversions des enums.
@immutable
class ExportableAppSettings {
  const ExportableAppSettings({
    required this.themeMode,
    required this.prefillExerciseName,
    required this.notificationMode,
  });

  final ThemeMode themeMode;
  final bool prefillExerciseName;
  final NotificationMode notificationMode;
}

/// Échec contrôlé d'une écriture de préférence.
///
/// La cause technique est volontairement absente de [toString] afin qu'elle
/// ne puisse pas être affichée accidentellement dans l'interface.
final class AppSettingsWriteException implements Exception {
  const AppSettingsWriteException();

  @override
  String toString() => 'AppSettingsWriteException';
}

class AppSettingsStorage implements SessionPermissionPromptStorage {
  static const _themeModeKey = 'theme_mode';
  static const _prefillExerciseNameKey = 'prefill_exercise_name';
  static const _notificationModeKey = 'notification_mode';
  static const _sessionNotificationExplanationPresentedKey =
      'session_notification_explanation_presented';

  /// Valeur par défaut : préremplissage activé, pour conserver le
  /// comportement historique de l'application sur toute installation qui
  /// n'a jamais modifié explicitement ce réglage.
  static const bool defaultPrefillExerciseName = true;

  /// Valeur par défaut : aucune notification, conformément à la spec
  /// ("Rien" est le comportement par défaut de l'application).
  static const NotificationMode defaultNotificationMode = NotificationMode.none;

  /// Valeur par défaut : suivre le système tant qu'aucun choix n'a été
  /// enregistré ou que la valeur stockée ne peut pas être interprétée.
  static const ThemeMode defaultThemeMode = ThemeMode.system;

  /// Sérialisation stable, indépendante du nom interne des valeurs de l'enum.
  /// Elle est publique pour être réutilisée par la sauvegarde v2.
  static String serializeThemeMode(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'system',
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
  };

  /// Désérialisation partagée avec la future restauration v2.
  /// Retourne `null` pour distinguer une valeur inconnue d'un thème valide.
  static ThemeMode? deserializeThemeMode(String value) => switch (value) {
    'system' => ThemeMode.system,
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => null,
  };

  /// Charge le thème sans jamais empêcher le démarrage de l'application.
  /// Une préférence absente, inconnue ou illisible suit le thème du système.
  Future<ThemeMode> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedValue = prefs.getString(_themeModeKey);
      if (storedValue == null) return defaultThemeMode;

      final themeMode = deserializeThemeMode(storedValue);
      if (themeMode != null) return themeMode;

      debugPrint('Préférence de thème inconnue ; utilisation du système.');
    } on Object catch (error) {
      debugPrint(
        'Lecture de la préférence de thème impossible '
        '(${error.runtimeType}) ; utilisation du système.',
      );
    }
    return defaultThemeMode;
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(
        _themeModeKey,
        serializeThemeMode(mode),
      );
      if (!saved) throw const AppSettingsWriteException();
    } on AppSettingsWriteException {
      rethrow;
    } on Object catch (error) {
      debugPrint(
        'Écriture de la préférence de thème impossible '
        '(${error.runtimeType}).',
      );
      throw const AppSettingsWriteException();
    }
  }

  /// Accès groupé réservé aux préférences exportables de l'utilisateur.
  Future<ExportableAppSettings> loadExportableSettings() async {
    return ExportableAppSettings(
      themeMode: await loadThemeMode(),
      prefillExerciseName: await loadPrefillExerciseName(),
      notificationMode: await loadNotificationMode(),
    );
  }

  /// Restaure les préférences exportables en réutilisant leurs écritures
  /// canoniques. Le service d'import v2 décidera de sa politique transactionnelle.
  Future<void> saveExportableSettings(ExportableAppSettings settings) async {
    await saveThemeMode(settings.themeMode);
    await savePrefillExerciseName(settings.prefillExerciseName);
    await saveNotificationMode(settings.notificationMode);
  }

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

  @override
  Future<bool> loadSessionNotificationExplanationPresented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sessionNotificationExplanationPresentedKey) ?? false;
  }

  @override
  Future<void> saveSessionNotificationExplanationPresented(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionNotificationExplanationPresentedKey, value);
  }
}
