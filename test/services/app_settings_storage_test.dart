import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/services/app_settings_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('thème', () {
    late void Function(String? message, {int? wrapWidth}) previousDebugPrint;
    late List<String> diagnostics;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      diagnostics = [];
      previousDebugPrint = debugPrint;
      debugPrint = (message, {wrapWidth}) {
        if (message != null) diagnostics.add(message);
      };
    });

    tearDown(() => debugPrint = previousDebugPrint);

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
      const storedValue = 'future-theme-sensitive-value';
      SharedPreferences.setMockInitialValues({'theme_mode': storedValue});

      expect(await AppSettingsStorage().loadThemeMode(), ThemeMode.system);
      expect(diagnostics, hasLength(1));
      expect(diagnostics.single, contains('Préférence de thème inconnue'));
      expect(diagnostics.single, contains('utilisation du système'));
      expect(diagnostics.single, isNot(contains(storedValue)));
    });

    test('une erreur de lecture revient au système sans bloquer', () async {
      const storedValue = 424242;
      SharedPreferences.setMockInitialValues({'theme_mode': storedValue});

      expect(await AppSettingsStorage().loadThemeMode(), ThemeMode.system);
      expect(diagnostics, hasLength(1));
      expect(
        diagnostics.single,
        contains('Lecture de la préférence de thème impossible'),
      );
      expect(diagnostics.single, contains('utilisation du système'));
      expect(diagnostics.single, isNot(contains('$storedValue')));
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
