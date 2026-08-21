import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/services/app_settings_exceptions.dart';

void main() {
  test('les exceptions de préférences ont un diagnostic stable et sûr', () {
    expect(
      const AppSettingsWriteException().toString(),
      'AppSettingsWriteException',
    );
    expect(
      const AppSettingsReadException().toString(),
      'AppSettingsReadException',
    );
  });
}
