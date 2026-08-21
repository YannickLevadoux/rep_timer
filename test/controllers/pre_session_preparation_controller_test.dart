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
    final controller = PreSessionPreparationController(
      countdownStorage: AppSettingsStorage(),
    );
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
    final controller = PreSessionPreparationController(
      countdownStorage: storage,
    );
    addTearDown(controller.dispose);
    await controller.load();

    await controller.setEnabled(false, selectDuration: () async => null);

    expect(controller.effectiveSeconds, 0);
    expect(await storage.loadPreSessionCountdownSeconds(), 10);
  });

  test('réactive la dernière durée connue sans rouvrir le sélecteur', () async {
    SharedPreferences.setMockInitialValues({
      AppSettingsStorage.preSessionCountdownSecondsKey: 10,
    });
    final controller = PreSessionPreparationController();
    addTearDown(controller.dispose);
    await controller.load();
    await controller.setEnabled(false, selectDuration: () async => null);

    var selectorCalls = 0;
    await controller.setEnabled(
      true,
      selectDuration: () async {
        selectorCalls++;
        return 5;
      },
    );

    expect(selectorCalls, 0);
    expect(controller.enabled, isTrue);
    expect(controller.effectiveSeconds, 10);
  });

  test(
    'active une durée temporaire sans persister la valeur globale',
    () async {
      final storage = AppSettingsStorage();
      final controller = PreSessionPreparationController(
        countdownStorage: storage,
      );
      addTearDown(controller.dispose);
      await controller.load();

      await controller.setEnabled(true, selectDuration: () async => 15);

      expect(controller.enabled, isTrue);
      expect(controller.seconds, 15);
      expect(controller.effectiveSeconds, 15);
      expect(await storage.loadPreSessionCountdownSeconds(), 0);

      await controller.setEnabled(false, selectDuration: () async => null);
      var selectorCalls = 0;
      await controller.setEnabled(
        true,
        selectDuration: () async {
          selectorCalls++;
          return 5;
        },
      );
      expect(selectorCalls, 0);
      expect(controller.effectiveSeconds, 15);
    },
  );

  test('un nouveau contrôleur repart de la valeur globale', () async {
    final first = PreSessionPreparationController();
    addTearDown(first.dispose);
    await first.load();
    await first.setEnabled(true, selectDuration: () async => 10);

    final next = PreSessionPreparationController();
    addTearDown(next.dispose);
    await next.load();

    expect(first.effectiveSeconds, 10);
    expect(next.enabled, isFalse);
    expect(next.effectiveSeconds, 0);
  });

  test('une annulation ou zéro conserve la préparation désactivée', () async {
    final controller = PreSessionPreparationController();
    addTearDown(controller.dispose);
    await controller.load();

    await controller.setEnabled(true, selectDuration: () async => null);
    expect(controller.enabled, isFalse);
    expect(controller.seconds, 0);

    await controller.setEnabled(true, selectDuration: () async => 0);
    expect(controller.enabled, isFalse);
    expect(controller.seconds, 0);
  });

  test('la valeur zéro charge un switch éteint', () async {
    final controller = PreSessionPreparationController();
    addTearDown(controller.dispose);

    await controller.load();

    expect(controller.seconds, 0);
    expect(controller.enabled, isFalse);
    expect(controller.effectiveSeconds, 0);
  });
}
