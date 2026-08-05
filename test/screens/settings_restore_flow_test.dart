import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/backup_import_models.dart';
import 'package:rep_timer/models/exportable_app_settings.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/screens/settings_screen.dart';
import 'package:rep_timer/services/backup_import_exception.dart';
import 'package:rep_timer/services/settings_transfer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('affiche le résumé v2 et annule sans aucune restauration', (
    tester,
  ) async {
    final transfer = _FakeTransferService(
      outcome: V2RestorePending(plan: _plan(), localDataWarning: true),
    );
    await _pumpSettings(tester, transfer);

    await _tapImport(tester);

    expect(find.text('Restaurer la sauvegarde ?'), findsOneWidget);
    expect(find.textContaining("Date d'export"), findsOneWidget);
    expect(find.text('Séances : 2'), findsOneWidget);
    expect(find.text('Historique : 1'), findsOneWidget);
    expect(find.text('Thème : Sombre'), findsOneWidget);
    expect(find.text('Préremplissage du nom : Désactivé'), findsOneWidget);
    expect(find.text('Notifications : Son'), findsOneWidget);
    expect(
      find.textContaining('Cette restauration remplacera définitivement'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Certaines données actuelles sont illisibles'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ListTile>(find.widgetWithText(ListTile, 'Exporter'))
          .enabled,
      isFalse,
    );

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(transfer.restoreCalls, 0);
    expect(find.text('Restaurer la sauvegarde ?'), findsNothing);
    expect(
      tester
          .widget<ListTile>(find.widgetWithText(ListTile, 'Exporter'))
          .enabled,
      isTrue,
    );
  });

  testWidgets('confirmer applique immédiatement le thème restauré', (
    tester,
  ) async {
    final transfer = _FakeTransferService(
      outcome: V2RestorePending(plan: _plan(), localDataWarning: false),
    );
    await tester.pumpWidget(_ThemeHost(transferService: transfer));
    await tester.pumpAndSettle();

    await _tapImport(tester);
    await tester.tap(find.text('Restaurer'));
    await tester.pumpAndSettle();

    expect(transfer.restoreCalls, 1);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(find.text('Sombre', skipOffstage: false), findsOneWidget);
    expect(
      tester.widget<Switch>(find.byType(Switch, skipOffstage: false)).value,
      isFalse,
    );
    expect(find.text('Son', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('Restauration terminée'), findsOneWidget);
  });

  testWidgets('un fichier invalide n’ouvre aucun dialogue et reste sûr', (
    tester,
  ) async {
    final transfer = _FakeTransferService(
      pickError: const BackupImportException(
        BackupImportFailureKind.invalidJson,
      ),
    );
    await _pumpSettings(tester, transfer);

    await _tapImport(tester);
    await tester.pumpAndSettle();

    expect(find.text('Restaurer la sauvegarde ?'), findsNothing);
    expect(
      find.text("Le fichier sélectionné n'est pas un fichier JSON valide."),
      findsOneWidget,
    );
    expect(find.textContaining('private-payload'), findsNothing);
  });

  testWidgets('un échec de restauration ne produit aucun faux succès', (
    tester,
  ) async {
    final transfer = _FakeTransferService(
      outcome: V2RestorePending(plan: _plan(), localDataWarning: false),
      restoreError: const BackupImportException(
        BackupImportFailureKind.restoreFailed,
      ),
    );
    await _pumpSettings(tester, transfer);

    await _tapImport(tester);
    await tester.tap(find.text('Restaurer'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Restauration terminée'), findsNothing);
    expect(
      find.textContaining('Les données précédentes ont été rétablies'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ListTile>(find.widgetWithText(ListTile, 'Exporter'))
          .enabled,
      isTrue,
    );
  });

  testWidgets('annuler le sélecteur ne modifie rien', (tester) async {
    final transfer = _FakeTransferService(outcome: null);
    await _pumpSettings(tester, transfer);

    await _tapImport(tester);
    await tester.pumpAndSettle();

    expect(transfer.restoreCalls, 0);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('un import v1 affiche le nombre de séances ajoutées', (
    tester,
  ) async {
    final transfer = _FakeTransferService(outcome: const V1ImportCompleted(3));
    await _pumpSettings(tester, transfer);

    await _tapImport(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Import terminé : 3 séance(s) importée(s).'),
      findsOneWidget,
    );
    expect(find.text('Restaurer la sauvegarde ?'), findsNothing);
    expect(transfer.restoreCalls, 0);
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

Future<void> _tapImport(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Importer'));
  await tester.tap(find.text('Importer'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

BackupV2RestorePlan _plan() => BackupV2RestorePlan(
  exportedAt: DateTime.parse('2026-08-05T10:30:00Z'),
  trainings: [
    Training(
      id: 'one',
      name: 'Une',
      groups: const [],
      createdAt: DateTime(2026),
    ),
    Training(
      id: 'two',
      name: 'Deux',
      groups: const [],
      createdAt: DateTime(2026),
    ),
  ],
  history: [
    TrainingHistoryEntry(
      id: 'history',
      trainingId: 'one',
      trainingName: 'Une',
      date: DateTime(2026),
      totalDuration: const Duration(minutes: 1),
    ),
  ],
  settings: const ExportableAppSettings(
    themeMode: ThemeMode.dark,
    prefillExerciseName: false,
    notificationMode: NotificationMode.sound,
  ),
);

class _FakeTransferService extends SettingsTransferService {
  _FakeTransferService({this.outcome, this.pickError, this.restoreError});

  final BackupImportOutcome? outcome;
  final BackupImportException? pickError;
  final BackupImportException? restoreError;
  int restoreCalls = 0;

  @override
  Future<BackupImportOutcome?> pickAndImport() async {
    if (pickError case final error?) throw error;
    return outcome;
  }

  @override
  Future<void> restoreV2(BackupV2RestorePlan plan) async {
    restoreCalls++;
    if (restoreError case final error?) throw error;
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
