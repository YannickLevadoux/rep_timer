import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/controllers/pre_session_preparation_controller.dart';
import 'package:rep_timer/services/app_settings_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('réutilise le stockage explicite ou celui des autorisations', () {
    final explicit = AppSettingsStorage();
    final permission = AppSettingsStorage();

    expect(
      resolvePreSessionCountdownStorage(
        countdownStorage: explicit,
        permissionStorage: permission,
      ),
      same(explicit),
    );
    expect(
      resolvePreSessionCountdownStorage(permissionStorage: permission),
      same(permission),
    );
    expect(resolvePreSessionCountdownStorage(), isA<AppSettingsStorage>());
  });

  test('active par défaut la durée positive chargée des paramètres', () async {
    SharedPreferences.setMockInitialValues({
      AppSettingsStorage.preSessionCountdownSecondsKey: 10,
    });
    final controller = PreSessionPreparationController(AppSettingsStorage());
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.seconds, 10);
    expect(controller.enabled, isTrue);
    expect(controller.effectiveSeconds, 10);
  });

  test('désactive seulement le prochain lancement sans persister', () async {
    SharedPreferences.setMockInitialValues({
      AppSettingsStorage.preSessionCountdownSecondsKey: 10,
    });
    final storage = AppSettingsStorage();
    final controller = PreSessionPreparationController(storage);
    addTearDown(controller.dispose);
    await controller.load();

    controller.setEnabled(false);

    expect(controller.effectiveSeconds, 0);
    expect(await storage.loadPreSessionCountdownSeconds(), 10);
  });

  test('la valeur zéro charge un switch éteint', () async {
    final controller = PreSessionPreparationController(AppSettingsStorage());
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.seconds, 0);
    expect(controller.enabled, isFalse);
    expect(controller.effectiveSeconds, 0);
  });
}
