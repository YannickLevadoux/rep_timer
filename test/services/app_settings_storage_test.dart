import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/services/app_settings_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persiste la présentation de l’explication des notifications', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = AppSettingsStorage();

    expect(
      await storage.loadSessionNotificationExplanationPresented(),
      isFalse,
    );

    await storage.saveSessionNotificationExplanationPresented(true);

    expect(
      await AppSettingsStorage().loadSessionNotificationExplanationPresented(),
      isTrue,
    );
  });
}
