import 'package:shared_preferences/shared_preferences.dart';

abstract interface class RestoreKeyValueStore {
  bool containsKey(String key);
  Object? read(String key);
  Future<bool> write(String key, Object value);
  Future<bool> remove(String key);
}

/// Adaptateur minimal de SharedPreferences utilisé uniquement par la
/// restauration v2 et son rollback.
class SharedPreferencesRestoreStore implements RestoreKeyValueStore {
  SharedPreferencesRestoreStore(this._preferences);

  final SharedPreferences _preferences;

  static Future<SharedPreferencesRestoreStore> create() async =>
      SharedPreferencesRestoreStore(await SharedPreferences.getInstance());

  @override
  bool containsKey(String key) => _preferences.containsKey(key);

  @override
  Object? read(String key) => _preferences.get(key);

  @override
  Future<bool> remove(String key) => _preferences.remove(key);

  @override
  Future<bool> write(String key, Object value) => switch (value) {
    String() => _preferences.setString(key, value),
    bool() => _preferences.setBool(key, value),
    int() => _preferences.setInt(key, value),
    double() => _preferences.setDouble(key, value),
    List<String>() => _preferences.setStringList(key, value),
    _ => throw StateError('Type de préférence non pris en charge.'),
  };
}
