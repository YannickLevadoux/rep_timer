import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/services/app_settings_storage.dart';
import 'package:rep_timer/widgets/dialogs/group_editor_settings_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppSettingsStorage.prefillExerciseNameKey: false,
    });
  });

  testWidgets('annuler conserve la préférence enregistrée', (tester) async {
    await tester.pumpWidget(const _DialogHarness());

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Paramètres du groupe'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(await AppSettingsStorage().loadPrefillExerciseName(), isFalse);
  });

  testWidgets('valider persiste la préférence modifiée', (tester) async {
    await tester.pumpWidget(const _DialogHarness());

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(await AppSettingsStorage().loadPrefillExerciseName(), isTrue);
  });
}

class _DialogHarness extends StatelessWidget {
  const _DialogHarness();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showGroupEditorSettingsDialog(context),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );
  }
}
