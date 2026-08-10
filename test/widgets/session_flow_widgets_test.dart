import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/widgets/dialogs/exit_session_dialog.dart';
import 'package:rep_timer/widgets/dialogs/incomplete_session_dialog.dart';
import 'package:rep_timer/widgets/session_finished_view.dart';

void main() {
  for (final scenario in <(String, String, ExitSessionChoice)>[
    ('continue', 'Continuer la séance', ExitSessionChoice.continueSession),
    ('termine', 'Terminer la session', ExitSessionChoice.finish),
    ('abandonne', 'Abandonner', ExitSessionChoice.abandon),
  ]) {
    testWidgets('le dialogue de sortie ${scenario.$1} la séance', (
      tester,
    ) async {
      ExitSessionChoice? result;
      await tester.pumpWidget(
        _dialogHost(
          onOpen: (context) async {
            result = await showExitSessionDialog(context);
          },
        ),
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      expect(find.text('Quitter la séance ?'), findsOneWidget);
      expect(find.text('Que souhaitez-vous faire ?'), findsOneWidget);

      await tester.tap(find.text(scenario.$2));
      await tester.pumpAndSettle();
      expect(result, scenario.$3);
    });
  }

  testWidgets('le dialogue incomplet ne peut pas être fermé silencieusement', (
    tester,
  ) async {
    IncompleteSessionChoice? result;
    await tester.pumpWidget(
      _dialogHost(
        onOpen: (context) async {
          result = await showIncompleteSessionDialog(context);
        },
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Séance incomplète'), findsOneWidget);
    expect(result, isNull);

    await tester.tap(find.text('Reprendre à un exercice de mon choix'));
    await tester.pumpAndSettle();
    expect(result, IncompleteSessionChoice.chooseStep);
  });

  testWidgets('le dialogue incomplet permet de terminer', (tester) async {
    IncompleteSessionChoice? result;
    await tester.pumpWidget(
      _dialogHost(
        onOpen: (context) async {
          result = await showIncompleteSessionDialog(context);
        },
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminer la séance'));
    await tester.pumpAndSettle();

    expect(result, IncompleteSessionChoice.finish);
  });

  testWidgets('la vue terminée affiche la durée et retourne à l’accueil', (
    tester,
  ) async {
    var backCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SessionFinishedView(
          trainingName: 'Séance du soir',
          totalDuration: const Duration(minutes: 12, seconds: 34),
          onBackHome: () => backCalls++,
        ),
      ),
    );

    expect(find.text('Séance du soir'), findsOneWidget);
    expect(find.text('Séance terminée !'), findsOneWidget);
    expect(find.text('Durée totale : 12:34'), findsOneWidget);

    await tester.tap(find.text("Retour à l'accueil"));
    expect(backCalls, 1);
  });
}

Widget _dialogHost({
  required Future<void> Function(BuildContext context) onOpen,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => onOpen(context),
          child: const Text('Ouvrir'),
        ),
      ),
    ),
  );
}
