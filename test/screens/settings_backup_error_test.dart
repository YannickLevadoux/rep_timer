import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/screens/settings_screen.dart';
import 'package:rep_timer/services/settings_transfer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('une erreur technique d’export affiche un message stable', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          themeMode: ThemeMode.system,
          onToggleTheme: () async => ThemeMode.light,
          transferService: _FailingTransferService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Exporter'));

    await tester.tap(find.text('Exporter'));
    await tester.pumpAndSettle();

    expect(find.text("La sauvegarde n'a pas pu être créée."), findsOneWidget);
    expect(find.textContaining('private-technical-detail'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      tester
          .widget<ListTile>(find.widgetWithText(ListTile, 'Exporter'))
          .enabled,
      isTrue,
    );
  });
}

class _FailingTransferService extends SettingsTransferService {
  @override
  Future<void> exportAndShare() async {
    throw StateError('private-technical-detail');
  }
}
