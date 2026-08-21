import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/main.dart' as app;
import 'package:rep_timer/services/app_settings_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('MyApp se construit correctement', (WidgetTester tester) async {
    await tester.pumpWidget(const app.MyApp());

    // Première frame
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Mes entraînements'), findsOneWidget);
  });

  testWidgets('main verrouille le portrait et restaure le thème avant runApp', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      AppSettingsStorage.themeModeKey: 'dark',
    });
    final platformCalls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await app.main();
    await tester.pumpAndSettle();

    expect(
      platformCalls,
      contains(
        isA<MethodCall>()
            .having(
              (call) => call.method,
              'method',
              'SystemChrome.setPreferredOrientations',
            )
            .having((call) => call.arguments, 'orientations', <String>[
              'DeviceOrientation.portraitUp',
              'DeviceOrientation.portraitDown',
            ]),
      ),
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(find.text('Mes entraînements'), findsOneWidget);
  });
}
