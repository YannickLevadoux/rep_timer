import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/widgets/statistic_badge.dart';

void main() {
  testWidgets('accepte des valeurs entières, fractionnaires et de durée', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: const [
            Expanded(child: _Badge(value: '7')),
            Expanded(child: _Badge(value: '18 / 20')),
            Expanded(child: _Badge(value: '01:02:03')),
          ],
        ),
      ),
    );

    expect(find.text('7'), findsOneWidget);
    expect(find.text('18 / 20'), findsOneWidget);
    expect(find.text('01:02:03'), findsOneWidget);
  });

  testWidgets('utilise les couleurs du thème sans surcharge', (tester) async {
    for (final theme in [ThemeData.light(), ThemeData.dark()]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Center(
            child: SizedBox(width: 100, child: _Badge(value: '42')),
          ),
        ),
      );

      final context = tester.element(find.byType(StatisticBadge));
      final colorScheme = Theme.of(context).colorScheme;
      final decoratedBox = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(StatisticBadge),
          matching: find.byType(DecoratedBox),
        ),
      );
      final decoration = decoratedBox.decoration as BoxDecoration;
      final border = decoration.border! as Border;
      final label = tester.widget<Text>(find.text('Test'));

      expect(border.top.color, colorScheme.outlineVariant);
      expect(label.style?.color, colorScheme.outline);
    }
  });
}

class _Badge extends StatelessWidget {
  const _Badge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return StatisticBadge(
      icon: Icons.numbers,
      label: 'Test',
      value: value,
      description: 'Valeur de test : $value',
    );
  }
}
