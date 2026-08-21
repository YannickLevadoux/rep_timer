import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/screens/export_screen.dart';
import 'package:rep_timer/screens/settings_screen.dart';
import 'package:rep_timer/services/settings_transfer_platform.dart';
import 'package:rep_timer/services/settings_transfer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'toutes les séances sont cochées et la sélection pilote Exporter',
    (tester) async {
      final transfer = _FakeTransferService(trainings: _trainings());
      await _pumpFromSettings(tester, transfer);

      final tiles = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(tiles.map((tile) => tile.value), everyElement(isTrue));

      await tester.tap(find.widgetWithText(TextButton, 'Tout décocher'));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Exporter'))
            .onPressed,
        isNull,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Tout cocher'));
      await tester.pump();
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Exporter'));
      await tester.pumpAndSettle();

      expect(transfer.exported.map((training) => training.name), ['Deux']);
      expect(find.text('Partage annulé.'), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Exporter'), findsOneWidget);
    },
  );

  for (final result in [
    TransferShareResult.success,
    TransferShareResult.unavailable,
  ]) {
    testWidgets('$result affiche le succès puis revient aux Paramètres', (
      tester,
    ) async {
      final transfer = _FakeTransferService(
        trainings: _trainings(),
        backupResult: result,
      );
      await _pumpFromSettings(tester, transfer);

      await tester.tap(
        find.widgetWithText(FilledButton, 'Sauvegarder les données'),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Paramètres'), findsOneWidget);
      expect(
        find.text('Fichier confié à la feuille de partage.'),
        findsOneWidget,
      );
    });
  }

  testWidgets('l’état vide explique l’absence et désactive Exporter', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExportScreen(
          transferService: _FakeTransferService(trainings: const []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucune séance enregistrée à exporter.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Exporter'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('les actions sont désactivées pendant un partage', (
    tester,
  ) async {
    final completer = Completer<TransferShareResult>();
    final transfer = _FakeTransferService(
      trainings: _trainings(),
      pendingBackup: completer.future,
    );
    await _pumpFromSettings(tester, transfer);

    await tester.tap(
      find.widgetWithText(FilledButton, 'Sauvegarder les données'),
    );
    await tester.tap(
      find.widgetWithText(FilledButton, 'Sauvegarder les données'),
    );
    await tester.pump();

    expect(transfer.backupCalls, 1);

    for (final button in tester.widgetList<FilledButton>(
      find.byType(FilledButton),
    )) {
      expect(button.onPressed, isNull);
    }
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Annuler'),
          )
          .onPressed,
      isNull,
    );

    completer.complete(TransferShareResult.dismissed);
    await tester.pumpAndSettle();
  });

  testWidgets('reste sans overflow en petite hauteur avec texte agrandi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: ExportScreen(
            transferService: _FakeTransferService(trainings: _trainings()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.fling(find.byType(ListView), const Offset(0, -2000), 3000);
    await tester.pumpAndSettle();
    expect(find.text('Annuler'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpFromSettings(
  WidgetTester tester,
  SettingsTransferService transfer,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SettingsScreen(
        themeMode: ThemeMode.system,
        onToggleTheme: () async => ThemeMode.light,
        transferService: transfer,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, 'Exporter'));
  await tester.pumpAndSettle();
}

List<Training> _trainings() => [
  Training(id: 'one', name: 'Une', groups: const [], createdAt: DateTime(2026)),
  Training(
    id: 'two',
    name: 'Deux',
    groups: const [],
    createdAt: DateTime(2026),
  ),
];

class _FakeTransferService extends SettingsTransferService {
  _FakeTransferService({
    required this.trainings,
    this.backupResult = TransferShareResult.dismissed,
    this.pendingBackup,
  });

  final List<Training> trainings;
  final TransferShareResult backupResult;
  final Future<TransferShareResult>? pendingBackup;
  List<Training> exported = const [];
  int backupCalls = 0;

  @override
  Future<List<Training>> loadTrainingsForExport() async => trainings;

  @override
  Future<TransferShareResult> exportTrainingsAndShare(
    List<Training> trainings,
  ) async {
    exported = trainings;
    return TransferShareResult.dismissed;
  }

  @override
  Future<TransferShareResult> exportAndShare() async {
    backupCalls++;
    return pendingBackup == null ? backupResult : pendingBackup!;
  }
}
