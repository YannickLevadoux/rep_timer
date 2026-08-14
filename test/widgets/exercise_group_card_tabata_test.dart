import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/widgets/exercise_group_card.dart';

void main() {
  testWidgets('la carte Tabata résume sa position sans Mono', (tester) async {
    final group = ExerciseGroup.tabata(id: 'tabata')
      ..rounds = 8
      ..finalRestDuration = const Duration(seconds: 17);

    await _pumpCard(tester, group, hasFollowingGroup: false);

    expect(find.text('Tabata · 8 cycles · 03:50'), findsOneWidget);
    expect(find.textContaining('Mono'), findsNothing);

    await _pumpCard(tester, group, hasFollowingGroup: true);

    expect(find.text('Tabata · 8 cycles · 04:07'), findsOneWidget);
  });

  testWidgets('les actions de la carte gardent une cible de 48 dp', (
    tester,
  ) async {
    await _pumpCard(tester, ExerciseGroup.tabata(id: 'tabata'));

    expect(
      tester.getSize(find.byTooltip('Éditer le groupe')),
      const Size(48, 48),
    );
    expect(
      tester.getSize(find.byTooltip('Supprimer le groupe')),
      const Size(48, 48),
    );
    expect(
      tester.getSize(find.byType(ReorderableDragStartListener)),
      const Size(48, 48),
    );
  });

  testWidgets('la carte reste stable à 360 × 640 avec texte agrandi', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final group = ExerciseGroup.tabata(id: 'tabata')
      ..name = 'Tabata avec un nom particulièrement long'
      ..rounds = 999;

    await _pumpCard(tester, group, theme: ThemeData.dark(), textScale: 2);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Tabata · 999 cycles'), findsOneWidget);
  });
}

Future<void> _pumpCard(
  WidgetTester tester,
  ExerciseGroup group, {
  bool hasFollowingGroup = false,
  ThemeData? theme,
  double textScale = 1,
}) => tester.pumpWidget(
  MaterialApp(
    theme: theme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: ExerciseGroupCard(
        group: group,
        onDelete: () {},
        onEdit: () {},
        onExpanded: (_) {},
        index: 0,
        expanded: false,
        hasFollowingGroup: hasFollowingGroup,
      ),
    ),
  ),
);
