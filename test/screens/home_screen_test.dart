import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/controllers/home_controller.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/screens/home_screen.dart';
import 'package:rep_timer/screens/quick_session_screen.dart';
import 'package:rep_timer/screens/training_editor.dart';
import 'package:rep_timer/screens/training_history.dart';
import 'package:rep_timer/screens/training_summary.dart';
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

  testWidgets(
    'masque les actions sans sélection puis affiche les deux lignes',
    (tester) async {
      final store = _FakeTrainingStore(
        trainings: [
          _training('one', 'Séance une'),
          _training('two', 'Séance deux'),
        ],
      );
      await _pumpHome(tester, store);

      expect(find.byTooltip('Dupliquer la séance'), findsNothing);
      expect(find.byTooltip('Supprimer la séance'), findsNothing);
      expect(find.text('Éditer'), findsNothing);
      expect(find.text('Commencer'), findsNothing);

      await tester.tap(find.text('Séance une'));
      await tester.pump();

      final primary = find.byKey(const Key('home-primary-actions-one'));
      final secondary = find.byKey(const Key('home-secondary-actions-one'));
      final duplicate = find.byTooltip('Dupliquer la séance');
      final delete = find.byTooltip('Supprimer la séance');
      final edit = find.widgetWithText(OutlinedButton, 'Éditer');
      expect(primary, findsOneWidget);
      expect(secondary, findsOneWidget);
      expect(duplicate, findsOneWidget);
      expect(delete, findsOneWidget);
      expect(
        find.descendant(of: primary, matching: find.text('Éditer')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: secondary, matching: find.text('Commencer')),
        findsOneWidget,
      );
      expect(tester.getSize(secondary).width, tester.getSize(primary).width);
      expect(tester.getSize(duplicate), const Size.square(48));
      expect(tester.getSize(delete), tester.getSize(duplicate));
      expect(
        tester.getCenter(duplicate).dx,
        lessThan(tester.getCenter(delete).dx),
      );
      expect(tester.getCenter(delete).dx, lessThan(tester.getCenter(edit).dx));
      expect(
        tester.getSize(edit).width,
        greaterThanOrEqualTo(tester.getSize(primary).width / 2),
      );

      await tester.tap(find.text('Séance deux'));
      await tester.pump();

      expect(primary, findsNothing);
      expect(find.byKey(const Key('home-primary-actions-two')), findsOneWidget);
    },
  );

  testWidgets('conserve les parcours Éditer et Commencer', (tester) async {
    final store = _FakeTrainingStore(
      trainings: [_training('one', 'Séance une')],
    );
    await _pumpHome(tester, store);
    await tester.tap(find.text('Séance une'));
    await tester.pump();

    await tester.tap(find.text('Éditer'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingEditor), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingSummaryScreen), findsOneWidget);
  });

  testWidgets('duplique toujours la séance sélectionnée', (tester) async {
    final store = _FakeTrainingStore(
      trainings: [_training('one', 'Séance une')],
    );
    await _pumpHome(tester, store);
    await tester.tap(find.text('Séance une'));
    await tester.pump();

    await tester.tap(find.byTooltip('Dupliquer la séance'));
    await tester.pumpAndSettle();
    expect(find.text('Dupliquer la séance'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Copier'));
    await tester.pumpAndSettle();

    expect(store.savedTrainings, hasLength(1));
    expect(store.savedTrainings.single.name, 'Séance une - Copie');
    expect(find.text('Séance une - Copie'), findsOneWidget);
  });

  testWidgets('annule puis confirme la suppression de la bonne séance', (
    tester,
  ) async {
    final store = _FakeTrainingStore(
      trainings: [
        _training('one', 'Séance une'),
        _training('two', 'Séance deux'),
      ],
    );
    await _pumpHome(tester, store);
    await tester.tap(find.text('Séance deux'));
    await tester.pump();

    await tester.tap(find.byTooltip('Supprimer la séance'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer la séance ?'), findsOneWidget);
    expect(
      find.text('Cette action est irréversible. Supprimer "Séance deux" ?'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
    await tester.pumpAndSettle();
    expect(store.deletedIds, isEmpty);
    expect(find.text('Séance deux'), findsOneWidget);
    expect(find.byTooltip('Supprimer la séance'), findsOneWidget);

    await tester.tap(find.byTooltip('Supprimer la séance'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();

    expect(store.deletedIds, ['two']);
    expect(find.text('Séance deux'), findsNothing);
    expect(find.text('Séance une'), findsOneWidget);
    expect(find.byTooltip('Supprimer la séance'), findsNothing);
    expect(find.text('Éditer'), findsNothing);
    expect(find.text('Commencer'), findsNothing);
  });

  testWidgets('désactive Supprimer lorsque les mutations sont bloquées', (
    tester,
  ) async {
    final store = _FakeTrainingStore(
      trainings: [_training('one', 'Séance une')],
      partial: true,
    );
    await _pumpHome(tester, store);
    await tester.tap(find.text('Séance une'));
    await tester.pump();

    final deleteButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.delete),
    );
    expect(deleteButton.onPressed, isNull);
    await tester.tap(find.byTooltip('Supprimer la séance'));
    await tester.pump();
    expect(find.text('Supprimer la séance ?'), findsNothing);
    expect(store.deletedIds, isEmpty);
  });

  testWidgets('affiche le blocage défensif du stockage sans supprimer', (
    tester,
  ) async {
    final store = _FakeTrainingStore(
      trainings: [_training('one', 'Séance une')],
      blockDeletion: true,
    );
    await _pumpHome(tester, store);
    await tester.tap(find.text('Séance une'));
    await tester.pump();

    await tester.tap(find.byTooltip('Supprimer la séance'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        "Suppression impossible : certaines séances n'ont pas pu être lues.",
      ),
      findsOneWidget,
    );
    expect(store.deletedIds, isEmpty);
    expect(find.text('Séance une'), findsOneWidget);
  });

  testWidgets('évite les débordements sur petite largeur et texte agrandi', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(240, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = _FakeTrainingStore(
      trainings: [_training('one', 'Séance une')],
    );

    await _pumpHome(tester, store, textScale: 2);
    await tester.tap(find.text('Séance une'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Dupliquer la séance'), findsOneWidget);
    expect(find.byTooltip('Supprimer la séance'), findsOneWidget);
    expect(find.text('Éditer'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
  });
}

Future<void> _pumpHome(
  WidgetTester tester,
  _FakeTrainingStore store, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: HomePage(
            themeMode: ThemeMode.system,
            onToggleTheme: () async => ThemeMode.light,
            controller: HomeController(storage: store),
            recoveryService: const _NoPendingSessionResolver(),
            historyStorage: _FakeHistoryStore(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _NoPendingSessionResolver implements PendingSessionRecoveryResolver {
  const _NoPendingSessionResolver();

  @override
  Future<PendingSessionRecoveryDecision> resolve() async =>
      const NoPendingSession(NoPendingSessionReason.absent);
}

class _FakeTrainingStore implements TrainingStore {
  _FakeTrainingStore({
    List<Training> trainings = const [],
    this.partial = false,
    this.blockDeletion = false,
  }) : _trainings = List.of(trainings);

  final bool partial;
  final bool blockDeletion;
  final List<Training> _trainings;
  final List<Training> savedTrainings = [];
  final List<String> deletedIds = [];

  @override
  Future<StorageReadResult<List<Training>>> loadTrainings() async {
    if (partial) {
      return StorageReadPartial(
        List.of(_trainings),
        rejectedIndexes: const [1],
      );
    }
    if (_trainings.isEmpty) return const StorageNoData();
    return StorageReadSuccess(List.of(_trainings));
  }

  @override
  Future<void> addOrUpdateTraining(Training training) async {
    savedTrainings.add(training);
    _trainings.add(training);
  }

  @override
  Future<void> deleteTraining(String id) async {
    if (blockDeletion) {
      throw const StorageMutationBlockedException(StorageBlockedState.partial);
    }
    deletedIds.add(id);
    _trainings.removeWhere((training) => training.id == id);
  }
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

Training _training(String id, String name) =>
    Training(id: id, name: name, groups: const [], createdAt: DateTime(2026));
