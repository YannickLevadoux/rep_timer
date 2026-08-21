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

  test('regroupe les préférences exportables sans régression', () async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'dark',
      'prefill_exercise_name': false,
      'notification_mode': 'sound',
      'pre_session_countdown_seconds': 15,
    });

    final settings = await AppSettingsStorage().loadExportableSettings();

    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.prefillExerciseName, isFalse);
    expect(settings.notificationMode, NotificationMode.sound);
    expect(settings.preSessionCountdownSeconds, 15);
  });

  test('le groupe exportable utilise tous les défauts documentés', () async {
    SharedPreferences.setMockInitialValues({});

    final settings = await AppSettingsStorage().loadExportableSettings();

    expect(settings.themeMode, ThemeMode.system);
    expect(settings.prefillExerciseName, isTrue);
    expect(settings.notificationMode, NotificationMode.none);
    expect(settings.preSessionCountdownSeconds, 0);
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

  test(
    'le groupe exportable refuse une notification inconnue ou illisible',
    () async {
      for (final value in <Object>['future-mode', 42]) {
        SharedPreferences.setMockInitialValues({'notification_mode': value});

        await expectLater(
          AppSettingsStorage().loadExportableSettings(),
          throwsA(isA<AppSettingsReadException>()),
        );
      }
    },
  );

  test('restaure toutes les préférences exportables', () async {
    SharedPreferences.setMockInitialValues({});
    const settings = ExportableAppSettings(
      themeMode: ThemeMode.light,
      prefillExerciseName: false,
      notificationMode: NotificationMode.vibration,
      preSessionCountdownSeconds: 9,
    );

    await AppSettingsStorage().saveExportableSettings(settings);

    final restored = await AppSettingsStorage().loadExportableSettings();
    expect(restored.themeMode, ThemeMode.light);
    expect(restored.prefillExerciseName, isFalse);
    expect(restored.notificationMode, NotificationMode.vibration);
    expect(restored.preSessionCountdownSeconds, 9);
  });

  test('lit et persiste le mode de notification', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = AppSettingsStorage();

    expect(await storage.loadNotificationMode(), NotificationMode.none);
    await storage.saveNotificationMode(NotificationMode.sound);
    expect(await storage.loadNotificationMode(), NotificationMode.sound);
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

  group('compte à rebours exportable', () {
    test('lit absence, 0 et 15, puis replie les valeurs illisibles', () async {
      for (final entry in <Object?, int>{
        null: 0,
        0: 0,
        15: 15,
        -1: 0,
        16: 0,
      }.entries) {
        SharedPreferences.setMockInitialValues({
          if (entry.key != null) 'pre_session_countdown_seconds': entry.key!,
        });
        expect(
          await AppSettingsStorage().loadPreSessionCountdownSeconds(),
          entry.value,
        );
      }
      SharedPreferences.setMockInitialValues({
        'pre_session_countdown_seconds': 'illisible',
      });
      expect(await AppSettingsStorage().loadPreSessionCountdownSeconds(), 0);
    });

    test('persiste les bornes et refuse toute valeur hors contrat', () async {
      final storage = AppSettingsStorage();
      for (final value in [0, 15]) {
        await storage.savePreSessionCountdownSeconds(value);
        expect(await storage.loadPreSessionCountdownSeconds(), value);
      }
      for (final value in [-1, 16]) {
        await expectLater(
          storage.savePreSessionCountdownSeconds(value),
          throwsA(isA<AppSettingsWriteException>()),
        );
      }
    });

    test('bloque un export si la valeur locale est hors bornes', () async {
      SharedPreferences.setMockInitialValues({
        'pre_session_countdown_seconds': 16,
      });
      await expectLater(
        AppSettingsStorage().loadExportableSettings(),
        throwsA(isA<AppSettingsReadException>()),
      );
    });
  });
}
