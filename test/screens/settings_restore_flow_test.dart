import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/backup_import_models.dart';
import 'package:rep_timer/models/exportable_app_settings.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/screens/import_screen.dart';
import 'package:rep_timer/screens/settings_screen.dart';
import 'package:rep_timer/services/backup_import_exception.dart';
import 'package:rep_timer/services/settings_transfer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Paramètres ouvre les deux écrans et Annuler revient', (
    tester,
  ) async {
    final transfer = _FakeTransferService();
    await _pumpSettings(tester, transfer);

    await tester.tap(find.widgetWithText(ListTile, 'Importer'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Importer'), findsOneWidget);
    expect(find.text('Importer des séances'), findsWidgets);
    expect(find.text('Restaurer les données'), findsWidgets);
    expect(find.textContaining('remplace définitivement'), findsOneWidget);
    expect(find.byTooltip("Aide sur l'import"), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Annuler'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Exporter'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Exporter'), findsOneWidget);
    expect(find.text('Exporter des séances'), findsOneWidget);
    expect(find.text('Sauvegarder les données'), findsWidgets);
    expect(find.byTooltip("Aide sur l'export"), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Paramètres'), findsOneWidget);
  });

  testWidgets('annuler le sélecteur affiche un snack et reste sur Importer', (
    tester,
  ) async {
    await _pumpSettings(tester, _FakeTransferService());
    await _openImport(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Importer des séances'));
    await tester.pumpAndSettle();

    expect(find.text('Sélection de fichier annulée.'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Importer'), findsOneWidget);
  });

  testWidgets(
    'un import réussi annonce le nombre puis revient aux Paramètres',
    (tester) async {
      final transfer = _FakeTransferService(importCount: 3);
      await _pumpSettings(tester, transfer);
      await _openImport(tester);

      await tester.tap(
        find.widgetWithText(FilledButton, 'Importer des séances'),
      );
      await tester.pumpAndSettle();

      expect(transfer.importCalls, 1);
      expect(find.widgetWithText(AppBar, 'Paramètres'), findsOneWidget);
      expect(
        find.text('Import terminé : 3 séance(s) ajoutée(s).'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'un double appui ne lance qu’un sélecteur et désactive les actions',
    (tester) async {
      final completer = Completer<int?>();
      final transfer = _FakeTransferService(pendingImport: completer.future);
      await _pumpSettings(tester, transfer);
      await _openImport(tester);

      final importButton = find.widgetWithText(
        FilledButton,
        'Importer des séances',
      );
      await tester.tap(importButton);
      await tester.tap(importButton);
      await tester.pump();

      expect(transfer.importCalls, 1);
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

      completer.complete(null);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('un v3 choisi pour les séances est orienté sans navigation', (
    tester,
  ) async {
    final transfer = _FakeTransferService(
      importError: const BackupImportException(
        BackupImportFailureKind.wrongTrainingImportPath,
      ),
    );
    await _pumpSettings(tester, transfer);
    await _openImport(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Importer des séances'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Restaurer les données'), findsWidgets);
    expect(find.widgetWithText(AppBar, 'Importer'), findsOneWidget);
    expect(transfer.restoreCalls, 0);
  });

  testWidgets('la sauvegarde vide affiche l’avertissement destructif exact', (
    tester,
  ) async {
    final transfer = _FakeTransferService(
      restorePending: RestorePending(
        plan: _emptyPlan(),
        localDataWarning: false,
      ),
    );
    await _pumpSettings(tester, transfer);
    await _openImport(tester);

    await tester.tap(
      find.widgetWithText(FilledButton, 'Restaurer les données'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Cette sauvegarde ne contient aucune séance ni aucun historique. '
        'La restauration supprimera définitivement toutes vos séances et tout '
        'votre historique actuels, puis appliquera les préférences contenues '
        'dans le fichier.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
    await tester.pumpAndSettle();
    expect(transfer.restoreCalls, 0);
    expect(find.widgetWithText(AppBar, 'Importer'), findsOneWidget);
  });

  for (final scenario in [
    (
      plan: _planWithOnlyHistory(),
      message: 'Cette sauvegarde ne contient aucune séance.',
    ),
    (
      plan: _planWithOnlyTraining(),
      message: 'Cette sauvegarde ne contient aucun historique.',
    ),
  ]) {
    testWidgets('${scenario.message} adapte l’avertissement', (tester) async {
      final transfer = _FakeTransferService(
        restorePending: RestorePending(
          plan: scenario.plan,
          localDataWarning: false,
        ),
      );
      await _pumpSettings(tester, transfer);
      await _openImport(tester);

      await tester.tap(
        find.widgetWithText(FilledButton, 'Restaurer les données'),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining(scenario.message), findsOneWidget);
      expect(find.textContaining('supprimera définitivement'), findsOneWidget);
    });
  }

  testWidgets('restaurer applique le thème puis revient aux Paramètres', (
    tester,
  ) async {
    final transfer = _FakeTransferService(
      restorePending: RestorePending(
        plan: _emptyPlan(themeMode: ThemeMode.dark),
        localDataWarning: false,
      ),
    );
    await tester.pumpWidget(_ThemeHost(transferService: transfer));
    await tester.pumpAndSettle();
    await _openImport(tester);

    await tester.tap(
      find.widgetWithText(FilledButton, 'Restaurer les données'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Restaurer'));
    await tester.pumpAndSettle();

    expect(transfer.restoreCalls, 1);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(find.widgetWithText(AppBar, 'Paramètres'), findsOneWidget);
    expect(find.textContaining('Restauration terminée'), findsOneWidget);
  });

  testWidgets('Importer défile sans overflow avec texte agrandi', (
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
          child: ImportScreen(
            transferService: _FakeTransferService(),
            onSettingsRestored: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.fling(find.byType(ListView), const Offset(0, -1500), 3000);
    await tester.pumpAndSettle();
    expect(find.text('Annuler'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpSettings(
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
}

Future<void> _openImport(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ListTile, 'Importer'));
  await tester.pumpAndSettle();
}

BackupRestorePlan _emptyPlan({ThemeMode themeMode = ThemeMode.system}) =>
    BackupRestorePlan(
      exportedAt: DateTime.parse('2026-08-20T10:30:00Z'),
      trainings: const [],
      history: const [],
      settings: ExportableAppSettings(
        themeMode: themeMode,
        prefillExerciseName: true,
        notificationMode: NotificationMode.none,
      ),
      formatVersion: 3,
    );

BackupRestorePlan _planWithOnlyHistory() => BackupRestorePlan(
  exportedAt: DateTime(2026),
  trainings: const [],
  history: [
    TrainingHistoryEntry(
      id: 'history',
      trainingId: 'old',
      trainingName: 'Ancienne',
      date: DateTime(2026),
      totalDuration: const Duration(minutes: 1),
    ),
  ],
  settings: _defaultSettings,
);

BackupRestorePlan _planWithOnlyTraining() => BackupRestorePlan(
  exportedAt: DateTime(2026),
  trainings: [
    Training(
      id: 'training',
      name: 'Séance',
      groups: const [],
      createdAt: DateTime(2026),
    ),
  ],
  history: const [],
  settings: _defaultSettings,
);

const _defaultSettings = ExportableAppSettings(
  themeMode: ThemeMode.system,
  prefillExerciseName: true,
  notificationMode: NotificationMode.none,
);

class _FakeTransferService extends SettingsTransferService {
  _FakeTransferService({
    this.importError,
    this.importCount,
    this.pendingImport,
    this.restorePending,
  });

  final BackupImportException? importError;
  final int? importCount;
  final Future<int?>? pendingImport;
  final RestorePending? restorePending;
  int importCalls = 0;
  int restoreCalls = 0;

  @override
  Future<List<Never>> loadTrainingsForExport() async => const [];

  @override
  Future<int?> pickAndImportTrainings() async {
    importCalls++;
    if (importError case final error?) throw error;
    return pendingImport == null ? importCount : pendingImport!;
  }

  @override
  Future<RestorePending?> pickAndPrepareRestore() async => restorePending;

  @override
  Future<void> restoreV2(BackupRestorePlan plan) async {
    restoreCalls++;
  }
}

class _ThemeHost extends StatefulWidget {
  const _ThemeHost({required this.transferService});

  final SettingsTransferService transferService;

  @override
  State<_ThemeHost> createState() => _ThemeHostState();
}

class _ThemeHostState extends State<_ThemeHost> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) => MaterialApp(
    themeMode: _themeMode,
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    home: SettingsScreen(
      themeMode: _themeMode,
      onToggleTheme: () async => ThemeMode.light,
      onThemeRestored: (mode) => setState(() => _themeMode = mode),
      transferService: widget.transferService,
    ),
  );
}
