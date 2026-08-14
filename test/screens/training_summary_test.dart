import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/screens/training_session.dart';
import 'package:rep_timer/screens/training_summary.dart';
import 'package:rep_timer/services/session_notification_permission_service.dart';
import 'package:rep_timer/widgets/statistic_badge.dart';

import '../support/fake_session_permission_platform.dart';

void main() {
  testWidgets('affiche une fois le titre et les trois badges comptabilisés', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final training = _training(
      name: 'Séance complète',
      groups: [
        _group('Premier', rounds: 3, exerciseCount: 1, restCount: 1),
        _group('Second', rounds: 2, exerciseCount: 2),
      ],
    );

    await _pumpSummary(tester, training);

    expect(find.text('Séance complète'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Séance complète'),
      ),
      findsOneWidget,
    );
    expect(find.text('Prêt ?'), findsOneWidget);
    final ready = tester.widget<Text>(find.text('Prêt ?'));
    expect(ready.textAlign, TextAlign.center);
    expect(
      ready.style,
      Theme.of(tester.element(find.text('Prêt ?'))).textTheme.headlineSmall,
    );

    _expectBadge(
      tester,
      key: const Key('summary-groups-badge'),
      icon: Icons.layers,
      label: 'Groupes',
      value: 2,
      description: 'Groupes : 2',
    );
    _expectBadge(
      tester,
      key: const Key('summary-exercises-badge'),
      icon: Icons.fitness_center,
      label: 'Exercices',
      value: 7,
      description: 'Exercices : 7',
    );
    _expectBadge(
      tester,
      key: const Key('summary-rests-badge'),
      icon: Icons.timer,
      label: 'Pauses',
      value: 3,
      description: 'Pauses : 3',
    );

    final badges = [
      find.byKey(const Key('summary-groups-badge')),
      find.byKey(const Key('summary-exercises-badge')),
      find.byKey(const Key('summary-rests-badge')),
    ];
    final top = tester.getTopLeft(badges.first).dy;
    final width = tester.getSize(badges.first).width;
    for (final badge in badges.skip(1)) {
      expect(tester.getTopLeft(badge).dy, top);
      expect(tester.getSize(badge).width, width);
    }

    semantics.dispose();
  });

  testWidgets(
    'reste sans débordement sur une petite largeur et texte agrandi',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(240, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final groups = List.generate(
        12,
        (index) => _group(
          'Groupe avec un nom long $index',
          rounds: 12,
          exerciseCount: 1,
          restCount: 1,
        ),
      );

      await _pumpSummary(
        tester,
        _training(
          name: 'Une séance possédant un nom particulièrement long',
          groups: groups,
        ),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Prêt ?'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('summary-exercises-badge')),
          matching: find.text('144'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('la zone statistique suit les thèmes clair et sombre', (
    tester,
  ) async {
    const lightBackground = Color(0xFFF4F2F8);
    const darkBackground = Color(0xFF121116);
    final training = _training(groups: [_group('Groupe')]);

    await _pumpSummary(
      tester,
      training,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: lightBackground,
      ),
    );
    await tester.pumpAndSettle();
    expect(_statisticsBackground(tester), lightBackground);

    await _pumpSummary(
      tester,
      training,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: darkBackground),
    );
    await tester.pumpAndSettle();
    expect(_statisticsBackground(tester), darkBackground);
  });

  testWidgets('une séance vide conserve son message et son bouton désactivé', (
    tester,
  ) async {
    await _pumpSummary(tester, _training(groups: []));

    expect(find.text('Cette séance ne contient aucun groupe.'), findsOneWidget);
    expect(find.text('Prêt ?'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Commencer'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('Commencer lance toujours TrainingSessionScreen', (tester) async {
    final training = _training(groups: [_group('Groupe')]);
    await _pumpSummary(tester, training);

    await tester.tap(find.text('Commencer'));
    await tester.pump(const Duration(milliseconds: 100));

    final session = tester.widget<TrainingSessionScreen>(
      find.byType(TrainingSessionScreen, skipOffstage: false),
    );
    expect(session.training, same(training));
  });

  testWidgets('une suite variable pilote statistiques et aperçu des tours', (
    tester,
  ) async {
    final group = ExerciseGroup(
      id: 'variable',
      name: 'Pyramide',
      type: GroupType.variableRepetitions,
      rounds: 99,
      repetitionSequence: [10, 12, 15],
      items: [
        TrainingItem(type: ItemType.exercise, name: 'Squats', repetitions: 5),
        TrainingItem(
          type: ItemType.rest,
          name: 'Pause',
          duration: const Duration(seconds: 10),
        ),
      ],
    );

    await _pumpSummary(tester, _training(groups: [group]));

    expect(find.text('× 3'), findsOneWidget);
    expect(find.text('3 tours · 10 → 12 → 15'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('summary-exercises-badge')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('summary-rests-badge')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('résume le Tabata selon sa position et son plan réel', (
    tester,
  ) async {
    final tabata = ExerciseGroup.tabata(id: 'tabata')
      ..rounds = 8
      ..finalRestDuration = const Duration(seconds: 17);

    await _pumpSummary(tester, _training(groups: [tabata]));

    expect(find.text('Tabata · 8 cycles · 03:50'), findsOneWidget);
    expect(find.text('× 8'), findsNothing);

    await _pumpSummary(tester, _training(groups: [tabata, _group('Suite')]));

    expect(find.text('Tabata · 8 cycles · 04:07'), findsOneWidget);
  });

  testWidgets('résume l’AMRAP et sa récupération selon sa position', (
    tester,
  ) async {
    final amrap = ExerciseGroup.amrap(id: 'amrap')
      ..postGroupRestDuration = const Duration(minutes: 1);

    await _pumpSummary(tester, _training(groups: [amrap]));
    expect(find.text('AMRAP · Effort · 02:00'), findsOneWidget);

    await _pumpSummary(tester, _training(groups: [amrap, _group('Suite')]));
    expect(find.text('AMRAP · Effort · 03:00'), findsOneWidget);
  });
}

void _expectBadge(
  WidgetTester tester, {
  required Key key,
  required IconData icon,
  required String label,
  required int value,
  required String description,
}) {
  final badge = find.byKey(key);
  expect(badge, findsOneWidget);
  expect(tester.widget(badge), isA<StatisticBadge>());
  expect(
    find.descendant(of: badge, matching: find.byIcon(icon)),
    findsOneWidget,
  );
  expect(
    find.descendant(of: badge, matching: find.text('$value')),
    findsOneWidget,
  );
  expect(
    find.descendant(of: badge, matching: find.text(label)),
    findsOneWidget,
  );
  expect(find.byTooltip(description), findsOneWidget);
  expect(find.bySemanticsLabel(description), findsOneWidget);
}

Color _statisticsBackground(WidgetTester tester) {
  return tester
      .widget<ColoredBox>(find.byKey(const Key('training-summary-statistics')))
      .color;
}

Future<void> _pumpSummary(
  WidgetTester tester,
  Training training, {
  ThemeData? theme,
  double textScale = 1,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: TrainingSummaryScreen(
        training: training,
        permissionService: SessionNotificationPermissionService(
          platform: GrantedSessionPermissionPlatform(),
        ),
      ),
    ),
  );
}

Training _training({
  String name = 'Séance',
  required List<ExerciseGroup> groups,
}) {
  return Training(
    id: 'training',
    name: name,
    groups: groups,
    createdAt: DateTime(2026),
  );
}

ExerciseGroup _group(
  String name, {
  int rounds = 1,
  int exerciseCount = 1,
  int restCount = 0,
}) {
  return ExerciseGroup(
    id: name,
    name: name,
    rounds: rounds,
    items: [
      for (var index = 0; index < exerciseCount; index++)
        TrainingItem(
          type: ItemType.exercise,
          name: 'Exercice $index',
          repetitions: 10,
        ),
      for (var index = 0; index < restCount; index++)
        TrainingItem(
          type: ItemType.rest,
          name: 'Pause',
          duration: const Duration(seconds: 30),
        ),
    ],
  );
}
