import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/widgets/exercise_icon_picker.dart';

void main() {
  testWidgets('met en évidence puis retourne l’icône choisie', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _PickerHarness()));

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Choisir une icône'), findsOneWidget);
    final selectedContainer = tester.widget<Container>(
      find
          .ancestor(
            of: find.byIcon(Icons.fitness_center),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = selectedContainer.decoration! as BoxDecoration;
    expect(decoration.color, isNotNull);
    expect(decoration.border, isNotNull);

    await tester.tap(find.byIcon(Icons.rowing));
    await tester.pumpAndSettle();

    expect(find.text('rowing'), findsOneWidget);
  });

  testWidgets('annuler ne retourne aucune icône', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _PickerHarness()));

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.text('aucune'), findsOneWidget);
  });
}

class _PickerHarness extends StatefulWidget {
  const _PickerHarness();

  @override
  State<_PickerHarness> createState() => _PickerHarnessState();
}

class _PickerHarnessState extends State<_PickerHarness> {
  String _result = 'en attente';

  Future<void> _openPicker() async {
    final result = await showExerciseIconPicker(
      context,
      currentIconName: 'fitness_center',
    );
    setState(() => _result = result ?? 'aucune');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          FilledButton(onPressed: _openPicker, child: const Text('Ouvrir')),
          Text(_result),
        ],
      ),
    );
  }
}
