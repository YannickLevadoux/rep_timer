import 'package:shared_preferences/shared_preferences.dart';

import '../validation/validation_contract.dart';
import 'app_settings_exceptions.dart';

const int defaultCountdownSeconds = 0;

bool isValidCountdownSeconds(int value) =>
    value >= 0 && value <= BusinessLimits.maximumPreSessionCountdownSeconds;

Future<int> loadCountdownSeconds(String storageKey) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(storageKey) ?? defaultCountdownSeconds;
    return isValidCountdownSeconds(value) ? value : defaultCountdownSeconds;
  } on Object {
    return defaultCountdownSeconds;
  }
}

Future<void> saveCountdownSeconds(String storageKey, int value) async {
  if (!isValidCountdownSeconds(value)) {
    throw const AppSettingsWriteException();
  }
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setInt(storageKey, value);
    if (!saved) throw const AppSettingsWriteException();
  } on AppSettingsWriteException {
    rethrow;
  } on Object {
    throw const AppSettingsWriteException();
  }
}
