import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/session_step.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/screens/session_progress.dart';

void main() {
  testWidgets(
    'affiche le compteur et les états terminé courant et en attente',
    (tester) async {
      final steps = _representativeSteps();

      await _openProgress(
        tester,
        steps: steps,
        completed: [true, false, false, false],
      );

      expect(find.text('Progression (1/4)'), findsOneWidget);

      final completedTile = _tileFor('Gainage');
      final completedIcon = tester.widget<Icon>(
        find.descendant(
          of: completedTile,
          matching: find.byIcon(Icons.check_circle),
        ),
      );
      expect(completedIcon.color, Colors.green);

      final currentTile = _tileFor('Mobilité');
      final currentTitle = tester.widget<Text>(find.text('Mobilité'));
      expect(currentTitle.style?.fontWeight, FontWeight.bold);
      expect(
        currentTitle.style?.color,
        Theme.of(tester.element(currentTile)).colorScheme.primary,
      );
      final currentIcon = tester.widget<Icon>(
        find.descendant(
          of: currentTile,
          matching: find.byIcon(Icons.radio_button_unchecked),
        ),
      );
      expect(
        currentIcon.color,
        Theme.of(tester.element(currentTile)).colorScheme.primary,
      );
      expect(
        find.descendant(of: currentTile, matching: find.byType(FadeTransition)),
        findsNWidgets(2),
      );
      expect(
        find.descendant(
          of: currentTile,
          matching: find.byIcon(Icons.radio_button_unchecked),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: currentTile,
          matching: find.byTooltip("Lancer cet exercice"),
        ),
        findsNothing,
      );

      final pendingTile = _tileFor('Pompes');
      final pendingIcon = tester.widget<Icon>(
        find.descendant(
          of: pendingTile,
          matching: find.byIcon(Icons.radio_button_unchecked),
        ),
      );
      expect(
        pendingIcon.color,
        Theme.of(tester.element(pendingTile)).colorScheme.outline,
      );
      expect(
        find.descendant(
          of: pendingTile,
          matching: find.byTooltip("Lancer cet exercice"),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('affiche le détail des différents types d’étapes', (
    tester,
  ) async {
    await _openProgress(
      tester,
      steps: _representativeSteps(),
      completed: [true, false, false, false],
    );

    expect(find.text('Circuit · répétition 1/2 · 30 s'), findsOneWidget);
    expect(find.text('Circuit · répétition 1/2 · Durée libre'), findsOneWidget);
    expect(find.text('Circuit · répétition 2/2 · × 12'), findsOneWidget);
    expect(find.text('Circuit · répétition 2/2 · 15 s'), findsOneWidget);
  });

  testWidgets('reflète périodiquement les références partagées', (
    tester,
  ) async {
    final completed = [true, false, false, false];
    var currentIndex = 1;
    await _openProgress(
      tester,
      steps: _representativeSteps(),
      completed: completed,
      currentIndexProvider: () => currentIndex,
    );

    completed[1] = true;
    currentIndex = 2;
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Progression (2/4)'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Pompes')).style?.fontWeight,
      FontWeight.bold,
    );
  });

  testWidgets('synchronise les deux fondus avec le contrôleur partagé', (
    tester,
  ) async {
    await _openProgress(
      tester,
      steps: _representativeSteps(),
      completed: [true, false, false, false],
    );
    final host = tester.state<_ProgressHostState>(
      find.byType(_ProgressHost, skipOffstage: false),
    );

    host._blinkController.value = 0.5;
    await tester.pump();

    final fades = tester
        .widgetList<FadeTransition>(
          find.descendant(
            of: _tileFor('Mobilité'),
            matching: find.byType(FadeTransition),
          ),
        )
        .toList();
    expect(fades, hasLength(2));
    expect(fades[0].opacity.value, closeTo(0.675, 0.001));
    expect(fades[1].opacity.value, closeTo(0.675, 0.001));
  });

  testWidgets('un appui sur l’étape courante reste sans effet', (tester) async {
    final selections = <int>[];
    await _openProgress(
      tester,
      steps: _representativeSteps(),
      completed: [true, false, false, false],
      onSelectStep: selections.add,
    );

    await tester.tap(find.text('Mobilité'));
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    expect(selections, isEmpty);
    expect(find.byType(SessionProgressScreen), findsOneWidget);
  });

  testWidgets('annuler le changement conserve l’écran sans callback', (
    tester,
  ) async {
    final selections = <int>[];
    await _openProgress(
      tester,
      steps: _representativeSteps(),
      completed: [true, false, false, false],
      onSelectStep: selections.add,
    );

    await tester.tap(find.text('Pompes'));
    await tester.pumpAndSettle();
    expect(find.text("Changer d'exercice ?"), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(selections, isEmpty);
    expect(find.byType(SessionProgressScreen), findsOneWidget);
    expect(find.text('Écran de séance'), findsNothing);
  });

  testWidgets(
    'confirmer appelle une fois le callback puis revient à la séance',
    (tester) async {
      final selections = <int>[];
      await _openProgress(
        tester,
        steps: _representativeSteps(),
        completed: [true, false, false, false],
        onSelectStep: selections.add,
      );

      await tester.tap(find.text('Pompes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(selections, [2]);
      expect(find.byType(SessionProgressScreen), findsNothing);
      expect(find.text('Écran de séance'), findsOneWidget);
    },
  );

  testWidgets('ne déborde pas sur petite largeur avec le texte agrandi', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(280, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final steps = _representativeSteps(longLabels: true);
    await _openProgress(
      tester,
      steps: steps,
      completed: [true, false, false, false],
      textScaler: const TextScaler.linear(2),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SessionProgressScreen), findsOneWidget);
  });

  testWidgets(
    'défile vers une étape courante initialement hors de la zone construite',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final steps = List.generate(
        100,
        (index) => _step(
          name: 'Exercice $index',
          round: index + 1,
          totalRounds: 100,
          repetitions: 10,
        ),
      );

      await _pumpProgressHost(
        tester,
        steps: steps,
        completed: List.filled(100, false),
        currentIndex: 50,
      );
      await tester.tap(find.byKey(const Key('open-progress')));
      await tester.pump();

      expect(find.text('Exercice 50'), findsNothing);

      await tester.pumpAndSettle();

      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.pixels, greaterThan(0));
      expect(find.text('Exercice 50'), findsOneWidget);
      expect(find.text('Exercice 49'), findsOneWidget);
      expect(find.text('Exercice 51'), findsOneWidget);
      expect(find.text('Exercice 52'), findsOneWidget);

      final listTop = tester.getTopLeft(find.byType(ListView)).dy;
      final listHeight = tester.getSize(find.byType(ListView)).height;
      final currentTop = tester.getTopLeft(_tileFor('Exercice 50')).dy;
      expect(currentTop - listTop, closeTo(listHeight * 0.3, 1));
    },
  );

  testWidgets('respecte les limites de défilement en début et fin de liste', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final steps = List.generate(
      100,
      (index) => _step(
        name: 'Exercice $index',
        round: index + 1,
        totalRounds: 100,
        repetitions: 10,
      ),
    );

    await _openProgress(
      tester,
      steps: steps,
      completed: List.filled(100, false),
      currentIndex: 1,
    );
    var scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, scrollable.position.minScrollExtent);
    expect(find.text('Exercice 1'), findsOneWidget);

    await _openProgress(
      tester,
      steps: steps,
      completed: List.filled(100, false),
      currentIndex: 99,
    );
    scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, scrollable.position.maxScrollExtent);
    expect(find.text('Exercice 99'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'conserve la liste en haut pour une liste vide ou un index invalide',
    (tester) async {
      final cases =
          <({List<SessionStep> steps, List<bool> completed, int index})>[
            (steps: [], completed: [], index: 0),
            (steps: [_step(name: 'Exercice 0')], completed: [false], index: -1),
            (steps: [_step(name: 'Exercice 0')], completed: [false], index: 1),
          ];

      for (final testCase in cases) {
        await _openProgress(
          tester,
          steps: testCase.steps,
          completed: testCase.completed,
          currentIndex: testCase.index,
        );

        final scrollable = tester.state<ScrollableState>(
          find.byType(Scrollable),
        );
        expect(scrollable.position.pixels, scrollable.position.minScrollExtent);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'ne recentre pas après un changement de progression ou un défilement manuel',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final steps = List.generate(
        100,
        (index) => _step(
          name: 'Exercice $index',
          round: index + 1,
          totalRounds: 100,
          repetitions: 10,
        ),
      );
      var currentIndex = 50;
      await _openProgress(
        tester,
        steps: steps,
        completed: List.filled(100, false),
        currentIndexProvider: () => currentIndex,
      );

      await tester.drag(find.byType(ListView), const Offset(0, 220));
      await tester.pumpAndSettle();
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      final manualOffset = scrollable.position.pixels;

      currentIndex = 70;
      await tester.pump(const Duration(seconds: 1));

      expect(scrollable.position.pixels, manualOffset);
    },
  );
}

Finder _tileFor(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(ListTile));

List<SessionStep> _representativeSteps({bool longLabels = false}) => [
  _step(
    name: longLabels ? 'Gainage chronométré au nom très long' : 'Gainage',
    duration: const Duration(seconds: 30),
  ),
  _step(
    name: longLabels
        ? 'Mobilité libre au nom particulièrement long'
        : 'Mobilité',
    isFreeDuration: true,
  ),
  _step(name: 'Pompes', round: 2, repetitions: 12),
  _step(
    name: 'Pause',
    round: 2,
    type: ItemType.rest,
    duration: const Duration(seconds: 15),
  ),
];

SessionStep _step({
  required String name,
  ItemType type = ItemType.exercise,
  int round = 1,
  int totalRounds = 2,
  int? repetitions,
  Duration? duration,
  bool isFreeDuration = false,
}) {
  final item = TrainingItem(
    type: type,
    name: name,
    repetitions: repetitions,
    duration: duration,
    isFreeDuration: isFreeDuration,
  );
  return SessionStep(
    group: ExerciseGroup(
      id: 'circuit',
      name: 'Circuit',
      rounds: totalRounds,
      items: [item],
    ),
    roundIndex: round,
    totalRounds: totalRounds,
    item: item,
  );
}

Future<void> _openProgress(
  WidgetTester tester, {
  required List<SessionStep> steps,
  required List<bool> completed,
  int currentIndex = 1,
  int Function()? currentIndexProvider,
  void Function(int)? onSelectStep,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await _pumpProgressHost(
    tester,
    steps: steps,
    completed: completed,
    currentIndex: currentIndex,
    currentIndexProvider: currentIndexProvider,
    onSelectStep: onSelectStep,
    textScaler: textScaler,
  );

  await tester.tap(find.byKey(const Key('open-progress')));
  await tester.pumpAndSettle();
}

Future<void> _pumpProgressHost(
  WidgetTester tester, {
  required List<SessionStep> steps,
  required List<bool> completed,
  int currentIndex = 1,
  int Function()? currentIndexProvider,
  void Function(int)? onSelectStep,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: _ProgressHost(
        steps: steps,
        completed: completed,
        currentIndexProvider: currentIndexProvider ?? () => currentIndex,
        onSelectStep: onSelectStep ?? (_) {},
      ),
    ),
  );
}

class _ProgressHost extends StatefulWidget {
  final List<SessionStep> steps;
  final List<bool> completed;
  final int Function() currentIndexProvider;
  final void Function(int) onSelectStep;

  const _ProgressHost({
    required this.steps,
    required this.completed,
    required this.currentIndexProvider,
    required this.onSelectStep,
  });

  @override
  State<_ProgressHost> createState() => _ProgressHostState();
}

class _ProgressHostState extends State<_ProgressHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  void _openProgress() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => SessionProgressScreen(
          steps: widget.steps,
          completed: widget.completed,
          currentIndexProvider: widget.currentIndexProvider,
          blinkController: _blinkController,
          onSelectStep: widget.onSelectStep,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: const Center(child: Text('Écran de séance')),
    floatingActionButton: FloatingActionButton(
      key: const Key('open-progress'),
      onPressed: _openProgress,
      child: const Icon(Icons.checklist),
    ),
  );
}
