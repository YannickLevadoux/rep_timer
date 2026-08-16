import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/controllers/home_controller.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/screens/home_screen.dart';
import 'package:rep_timer/screens/quick_session_screen.dart';
import 'package:rep_timer/screens/training_history.dart';
import 'package:rep_timer/services/json_prefs_storage.dart';
import 'package:rep_timer/services/pending_session_recovery_service.dart';
import 'package:rep_timer/services/training_history_storage.dart';
import 'package:rep_timer/services/training_storage.dart';

void main() {
  testWidgets('la destination Rapide ouvre la Session rapide', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          themeMode: ThemeMode.system,
          onToggleTheme: () async => ThemeMode.light,
          controller: HomeController(storage: _FakeTrainingStore()),
          recoveryService: const _NoPendingSessionResolver(),
          historyStorage: _FakeHistoryStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rapide'), findsOneWidget);
    await tester.tap(find.text('Rapide'));
    await tester.pumpAndSettle();

    expect(find.byType(QuickSessionScreen), findsOneWidget);
    expect(find.text('Session rapide'), findsOneWidget);
  });

  testWidgets('navigue vers l’historique avec ses dépendances injectées', (
    tester,
  ) async {
    final historyStorage = _FakeHistoryStore();

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          themeMode: ThemeMode.system,
          onToggleTheme: () async => ThemeMode.light,
          controller: HomeController(storage: _FakeTrainingStore()),
          recoveryService: const _NoPendingSessionResolver(),
          historyStorage: historyStorage,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Historique'));
    await tester.pumpAndSettle();

    expect(find.byType(TrainingHistoryScreen), findsOneWidget);
    expect(find.text('Aucune séance sur cette période'), findsOneWidget);
    expect(historyStorage.loadCalls, 1);
  });
}

class _NoPendingSessionResolver implements PendingSessionRecoveryResolver {
  const _NoPendingSessionResolver();

  @override
  Future<PendingSessionRecoveryDecision> resolve() async =>
      const NoPendingSession(NoPendingSessionReason.absent);
}

class _FakeTrainingStore implements TrainingStore {
  @override
  Future<StorageReadResult<List<Training>>> loadTrainings() async =>
      const StorageNoData();

  @override
  Future<void> addOrUpdateTraining(Training training) async {}

  @override
  Future<void> deleteTraining(String id) async {}
}

class _FakeHistoryStore implements TrainingHistoryStore {
  int loadCalls = 0;

  @override
  Future<StorageReadResult<List<TrainingHistoryEntry>>> loadHistory() async {
    loadCalls++;
    return const StorageNoData();
  }

  @override
  Future<void> deleteEntry(String id) async {}
}
