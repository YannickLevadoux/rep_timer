import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/services/app_settings_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('thème', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('utilise le système lorsque la clé est absente', () async {
      expect(await AppSettingsStorage().loadThemeMode(), ThemeMode.system);
    });

    for (final entry in <String, ThemeMode>{
      'system': ThemeMode.system,
      'light': ThemeMode.light,
      'dark': ThemeMode.dark,
    }.entries) {
      test('lit la valeur valide ${entry.key}', () async {
        SharedPreferences.setMockInitialValues({'theme_mode': entry.key});

        expect(await AppSettingsStorage().loadThemeMode(), entry.value);
      });
    }

    test('une valeur inconnue revient au système sans crash', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'future-theme'});

      expect(await AppSettingsStorage().loadThemeMode(), ThemeMode.system);
    });

    test('une erreur de lecture revient au système sans bloquer', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 42});

      expect(await AppSettingsStorage().loadThemeMode(), ThemeMode.system);
    });

    for (final entry in <ThemeMode, String>{
      ThemeMode.system: 'system',
      ThemeMode.light: 'light',
      ThemeMode.dark: 'dark',
    }.entries) {
      test('sauvegarde la valeur stable ${entry.value}', () async {
        await AppSettingsStorage().saveThemeMode(entry.key);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('theme_mode'), entry.value);
      });
    }
  });

  test('regroupe les trois préférences exportables sans régression', () async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'dark',
      'prefill_exercise_name': false,
      'notification_mode': 'sound',
    });

    final settings = await AppSettingsStorage().loadExportableSettings();

    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.prefillExerciseName, isFalse);
    expect(settings.notificationMode, NotificationMode.sound);
  });

  test('le groupe exportable utilise tous les défauts documentés', () async {
    SharedPreferences.setMockInitialValues({});

    final settings = await AppSettingsStorage().loadExportableSettings();

    expect(settings.themeMode, ThemeMode.system);
    expect(settings.prefillExerciseName, isTrue);
    expect(settings.notificationMode, NotificationMode.none);
  });

  test('le groupe exportable refuse une valeur réelle inconnue', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'private-theme'});

    await expectLater(
      AppSettingsStorage().loadExportableSettings(),
      throwsA(
        isA<AppSettingsReadException>().having(
          (error) => error.toString(),
          'diagnostic sûr',
          isNot(contains('private-theme')),
        ),
      ),
    );
  });

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
