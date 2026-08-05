import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/screens/home_screen.dart';
import 'package:rep_timer/screens/training_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('l’accueil sort du chargement et propose de réessayer', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'trainings': 'sensitive-invalid-json',
    });

    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.text("Les séances enregistrées n'ont pas pu être lues."),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.textContaining('sensitive-invalid-json'), findsNothing);
  });

  testWidgets(
    'l’accueil affiche les séances récupérées avec un avertissement',
    (tester) async {
      final raw = jsonEncode([
        _training('valide').toJson(),
        {'private': 'sensitive-payload'},
      ]);
      SharedPreferences.setMockInitialValues({'trainings': raw});

      await tester.pumpWidget(_homeApp());
      await tester.pumpAndSettle();

      expect(find.text('Séance valide'), findsOneWidget);
      expect(
        find.textContaining("Certaines données n'ont pas pu être lues"),
        findsOneWidget,
      );
      expect(find.textContaining('sensitive-payload'), findsNothing);
      final addButton = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(addButton.onPressed, isNull);

      await tester.tap(find.text('Séance valide'));
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.copy))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Éditer'),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('l’historique partiel avertit et interdit la suppression', (
    tester,
  ) async {
    final raw = jsonEncode([
      _historyEntry('valid').toJson(),
      {'private': 'sensitive-history'},
    ]);
    SharedPreferences.setMockInitialValues({'training_history': raw});

    await tester.pumpWidget(const MaterialApp(home: TrainingHistoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Séance valid'), findsOneWidget);
    expect(
      find.textContaining("Certaines séances de l'historique"),
      findsOneWidget,
    );
    expect(find.textContaining('sensitive-history'), findsNothing);
    final deleteButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.delete_outline),
    );
    expect(deleteButton.onPressed, isNull);
  });

  testWidgets(
    'l’historique illisible sort du chargement et permet de réessayer',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'training_history': 'sensitive-invalid-history',
      });

      await tester.pumpWidget(const MaterialApp(home: TrainingHistoryScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.text("L'historique enregistré n'a pas pu être lu."),
        findsOneWidget,
      );
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.textContaining('sensitive-invalid-history'), findsNothing);
    },
  );

  testWidgets('un checkpoint illisible avertit sans provoquer de crash', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'trainings': jsonEncode([_training('checkpoint').toJson()]),
      'session_checkpoint': 'sensitive-checkpoint-json',
    });

    await tester.pumpWidget(_homeApp());
    await tester.pumpAndSettle();

    expect(find.text('Séance checkpoint'), findsOneWidget);
    expect(
      find.textContaining("Certaines données n'ont pas pu être lues"),
      findsOneWidget,
    );
    expect(find.textContaining('sensitive-checkpoint-json'), findsNothing);
    expect(tester.takeException(), isNull);
    expect(
      (await SharedPreferences.getInstance()).getString('session_checkpoint'),
      'sensitive-checkpoint-json',
    );

    await tester.tap(find.text('Séance checkpoint'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Commencer'))
          .onPressed,
      isNull,
    );
  });
}

Widget _homeApp() {
  return MaterialApp(
    home: HomePage(
      themeMode: ThemeMode.system,
      onToggleTheme: () async => ThemeMode.light,
    ),
  );
}

Training _training(String id) {
  return Training(
    id: id,
    name: 'Séance $id',
    groups: const [],
    createdAt: DateTime(2026, 7, 1),
  );
}

TrainingHistoryEntry _historyEntry(String id) {
  return TrainingHistoryEntry(
    id: id,
    trainingId: 'training',
    trainingName: 'Séance $id',
    date: DateTime(2026, 7, 1),
    totalDuration: const Duration(minutes: 1),
  );
}
