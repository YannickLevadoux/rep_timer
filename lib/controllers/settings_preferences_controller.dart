import 'package:flutter/foundation.dart';

import '../models/notification_mode.dart';
import '../models/notification_sound.dart';
import '../services/app_settings_storage.dart';
import '../services/step_end_notification_service.dart';

/// État et actions des préférences simples de l'écran Paramètres.
class SettingsPreferencesController extends ChangeNotifier {
  SettingsPreferencesController(
    this._storage, {
    StepEndNotificationService? notificationService,
  }) : _notificationService =
           notificationService ?? StepEndNotificationService();

  final AppSettingsStorage _storage;
  final StepEndNotificationService _notificationService;
  bool _disposed = false;

  bool prefillExerciseName = AppSettingsStorage.defaultPrefillExerciseName;
  NotificationMode notificationMode =
      AppSettingsStorage.defaultNotificationMode;
  int preSessionCountdownSeconds =
      AppSettingsStorage.defaultPreSessionCountdownSeconds;

  Future<void> load() async {
    final values = await Future.wait<Object>([
      _storage.loadPrefillExerciseName(),
      _storage.loadNotificationMode(),
      _storage.loadPreSessionCountdownSeconds(),
    ]);
    if (_disposed) return;
    prefillExerciseName = values[0] as bool;
    notificationMode = values[1] as NotificationMode;
    preSessionCountdownSeconds = values[2] as int;
    notifyListeners();
  }

  Future<void> setPrefillExerciseName(bool value) async {
    prefillExerciseName = value;
    notifyListeners();
    await _storage.savePrefillExerciseName(value);
  }

  Future<void> cycleNotificationMode() async {
    notificationMode = notificationMode.next;
    notifyListeners();
    await _storage.saveNotificationMode(notificationMode);
    switch (notificationMode) {
      case NotificationMode.sound:
        await _notificationService.playPreview(NotificationSound.classic);
      case NotificationMode.vibration:
        await _notificationService.vibrate();
      case NotificationMode.none:
        break;
    }
  }

  Future<void> setPreSessionCountdownSeconds(int value) async {
    await _storage.savePreSessionCountdownSeconds(value);
    preSessionCountdownSeconds = value;
    notifyListeners();
  }

  void applyRestored(ExportableAppSettings settings) {
    prefillExerciseName = settings.prefillExerciseName;
    notificationMode = settings.notificationMode;
    preSessionCountdownSeconds = settings.preSessionCountdownSeconds;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _notificationService.dispose();
    super.dispose();
  }
}
