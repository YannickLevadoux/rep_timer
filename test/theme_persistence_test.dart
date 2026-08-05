import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/main.dart';
import 'package:rep_timer/services/app_settings_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('restaure le thème dès la première frame après reconstruction', (
    tester,
  ) async {
    final firstStorage = AppSettingsStorage();
    await firstStorage.saveThemeMode(ThemeMode.dark);

    await tester.pumpWidget(
      MyApp(
        initialThemeMode: await firstStorage.loadThemeMode(),
        settingsStorage: firstStorage,
      ),
    );

    expect(_materialApp(tester).themeMode, ThemeMode.dark);

    await tester.pumpWidget(const SizedBox.shrink());

    final rebuiltStorage = AppSettingsStorage();
    await tester.pumpWidget(
      MyApp(
        initialThemeMode: await rebuiltStorage.loadThemeMode(),
        settingsStorage: rebuiltStorage,
      ),
    );

    expect(_materialApp(tester).themeMode, ThemeMode.dark);
  });

  testWidgets('le changement depuis Paramètres est visible et persisté', (
    tester,
  ) async {
    final storage = AppSettingsStorage();
    await tester.pumpWidget(MyApp(settingsStorage: storage));
    await tester.pumpAndSettle();
    await _openSettings(tester);

    expect(find.text('Système'), findsOneWidget);
    await tester.tap(find.byTooltip(_systemThemeTooltip));
    await tester.pumpAndSettle();

    expect(_materialApp(tester).themeMode, ThemeMode.light);
    expect(find.text('Clair'), findsOneWidget);
    expect(await storage.loadThemeMode(), ThemeMode.light);
  });

  testWidgets(
    'un échec d’écriture conserve le thème confirmé et masque l’erreur',
    (tester) async {
      final storage = _FailingThemeStorage();
      await tester.pumpWidget(MyApp(settingsStorage: storage));
      await tester.pumpAndSettle();
      await _openSettings(tester);

      await tester.tap(find.byTooltip(_systemThemeTooltip));
      await tester.pumpAndSettle();

      expect(_materialApp(tester).themeMode, ThemeMode.system);
      expect(find.text('Système'), findsOneWidget);
      expect(
        find.text("Le thème n'a pas pu être enregistré. Réessayez."),
        findsOneWidget,
      );
      expect(find.textContaining('technical-secret'), findsNothing);
    },
  );
}

const _systemThemeTooltip = 'Thème : Système (appuyer pour changer)';

MaterialApp _materialApp(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp));

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Paramètres'));
  await tester.pumpAndSettle();
  expect(find.text('Paramètres'), findsOneWidget);
}

class _FailingThemeStorage extends AppSettingsStorage {
  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    throw StateError('technical-secret');
  }
}
