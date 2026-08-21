import 'package:flutter/foundation.dart';

import '../services/app_settings_storage.dart';

AppSettingsStorage resolvePreSessionCountdownStorage({
  AppSettingsStorage? countdownStorage,
  SessionPermissionPromptStorage? permissionStorage,
}) =>
    countdownStorage ??
    (permissionStorage is AppSettingsStorage
        ? permissionStorage
        : AppSettingsStorage());

/// Gère le choix de préparation propre au prochain lancement de séance.
///
/// La durée vient des paramètres, mais l'activation reste volontairement en
/// mémoire afin que ce choix n'altère pas la préférence globale.
class PreSessionPreparationController extends ChangeNotifier {
  PreSessionPreparationController(this._settingsStorage);

  final AppSettingsStorage _settingsStorage;

  Future<void>? _loading;
  bool _disposed = false;
  bool _loaded = false;
  bool _enabled = false;
  int _seconds = AppSettingsStorage.defaultPreSessionCountdownSeconds;

  bool get loaded => _loaded;
  bool get enabled => _enabled;
  int get seconds => _seconds;
  int get effectiveSeconds => _enabled ? _seconds : 0;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    final seconds = await _settingsStorage.loadPreSessionCountdownSeconds();
    if (_disposed) return;
    _seconds = seconds;
    _enabled = seconds > 0;
    _loaded = true;
    notifyListeners();
  }

  void setEnabled(bool enabled) {
    if (!_loaded || _enabled == enabled) return;
    _enabled = enabled;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
