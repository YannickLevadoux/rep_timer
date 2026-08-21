import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/screens/settings_screen.dart';
import 'package:rep_timer/services/app_settings_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('affiche le singulier, le pluriel et persiste le dialogue', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      AppSettingsStorage.preSessionCountdownSecondsKey: 1,
    });
    await _pumpSettings(tester);
    await _scrollToCountdown(tester);

    expect(find.text('Séances'), findsOneWidget);
    expect(find.text('1 seconde'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pre-session-countdown-setting')));
    await tester.pumpAndSettle();
    expect(find.text('0 = désactivé'), findsOneWidget);

    await tester.tap(find.byKey(const Key('increase-pre-session-countdown')));
    await tester.pump();
    expect(find.text('2 secondes'), findsOneWidget);
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.text('2 secondes'), findsOneWidget);
    expect(await AppSettingsStorage().loadPreSessionCountdownSeconds(), 2);
  });

  testWidgets('les boutons respectent exactement les bornes 0 et 15', (
    tester,
  ) async {
    await _pumpSettings(tester);
    await _scrollToCountdown(tester);
    await tester.tap(find.byKey(const Key('pre-session-countdown-setting')));
    await tester.pumpAndSettle();

    expect(find.text('Désactivé'), findsWidgets);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('decrease-pre-session-countdown')),
          )
          .onPressed,
      isNull,
    );

    for (var value = 0; value < 15; value++) {
      await tester.tap(find.byKey(const Key('increase-pre-session-countdown')));
    }
    await tester.pump();

    expect(find.text('15 secondes'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('increase-pre-session-countdown')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('place Séances entre Édition et Notifications', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpSettings(tester);

    final editingTop = tester.getTopLeft(find.text('Édition')).dy;
    final sessionTop = tester.getTopLeft(find.text('Séances')).dy;
    final notificationsTop = tester.getTopLeft(find.text('Notifications')).dy;

    expect(sessionTop, greaterThan(editingTop));
    expect(sessionTop, lessThan(notificationsTop));
  });
}

Future<void> _scrollToCountdown(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -400));
  await tester.pumpAndSettle();
}

Future<void> _pumpSettings(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SettingsScreen(
        themeMode: ThemeMode.system,
        onToggleTheme: () async => ThemeMode.light,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
