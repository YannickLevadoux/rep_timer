import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/app_settings_storage.dart';
import 'package:rep_timer/services/session_notification_permission_service.dart';
import 'package:rep_timer/services/session_start_permission_gate.dart';

void main() {
  test('détecte les durées fixes et libres, mais pas les répétitions', () {
    expect(
      sessionNeedsBackgroundTracking(
        _training(
          TrainingItem(
            type: ItemType.exercise,
            name: 'Temps',
            duration: const Duration(seconds: 30),
          ),
        ),
      ),
      isTrue,
    );
    expect(
      sessionNeedsBackgroundTracking(
        _training(
          TrainingItem(
            type: ItemType.exercise,
            name: 'Libre',
            isFreeDuration: true,
          ),
        ),
      ),
      isTrue,
    );
    expect(
      sessionNeedsBackgroundTracking(
        _training(
          TrainingItem(
            type: ItemType.exercise,
            name: 'Répétitions',
            repetitions: 12,
          ),
        ),
      ),
      isFalse,
    );
  });

  test('détecte une pause chronométrée produite par buildSessionSteps', () {
    final training = _trainingItems([
      TrainingItem(
        type: ItemType.rest,
        name: 'Pause',
        duration: const Duration(seconds: 10),
      ),
      TrainingItem(
        type: ItemType.exercise,
        name: 'Répétitions',
        repetitions: 10,
      ),
    ]);

    expect(sessionNeedsBackgroundTracking(training), isTrue);
  });

  testWidgets('Pas maintenant ne demande rien et poursuit le lancement', (
    tester,
  ) async {
    final platform = _FakePlatform();
    final storage = _FakeStorage();
    await _pumpGate(tester, platform: platform, storage: storage);

    await tester.tap(find.text('Démarrer'));
    await tester.pumpAndSettle();
    expect(find.text('Suivre la séance en arrière-plan'), findsOneWidget);

    await tester.tap(find.text('Pas maintenant'));
    await tester.pumpAndSettle();

    expect(find.text('Lancements : 1'), findsOneWidget);
    expect(platform.notificationRequests, 0);
    expect(platform.batteryRequests, 0);
    expect(storage.presented, isTrue);
  });

  testWidgets('Autoriser demande seulement la notification puis poursuit', (
    tester,
  ) async {
    final platform = _FakePlatform();
    final storage = _FakeStorage();
    await _pumpGate(tester, platform: platform, storage: storage);

    await tester.tap(find.text('Démarrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autoriser'));
    await tester.pumpAndSettle();

    expect(find.text('Lancements : 1'), findsOneWidget);
    expect(platform.notificationRequests, 1);
    expect(platform.batteryRequests, 0);
  });

  testWidgets("l'explication n'est affichée qu'une seule fois", (tester) async {
    final platform = _FakePlatform();
    final storage = _FakeStorage();
    await _pumpGate(tester, platform: platform, storage: storage);

    await tester.tap(find.text('Démarrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pas maintenant'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Démarrer'));
    await tester.pumpAndSettle();

    expect(find.text('Suivre la séance en arrière-plan'), findsNothing);
    expect(find.text('Lancements : 2'), findsOneWidget);
  });

  testWidgets("une autorisation accordée évite l'explication", (tester) async {
    final platform = _FakePlatform(
      notificationStatus: SessionNotificationPermissionStatus.granted,
    );
    await _pumpGate(tester, platform: platform, storage: _FakeStorage());

    await tester.tap(find.text('Démarrer'));
    await tester.pumpAndSettle();

    expect(find.text('Suivre la séance en arrière-plan'), findsNothing);
    expect(find.text('Lancements : 1'), findsOneWidget);
  });

  testWidgets('une séance en répétitions poursuit sans explication', (
    tester,
  ) async {
    await _pumpGate(
      tester,
      platform: _FakePlatform(),
      storage: _FakeStorage(),
      training: _training(
        TrainingItem(
          type: ItemType.exercise,
          name: 'Répétitions',
          repetitions: 15,
        ),
      ),
    );

    await tester.tap(find.text('Démarrer'));
    await tester.pumpAndSettle();

    expect(find.text('Suivre la séance en arrière-plan'), findsNothing);
    expect(find.text('Lancements : 1'), findsOneWidget);
  });

  testWidgets('une séance en durée libre affiche l’explication', (
    tester,
  ) async {
    await _pumpGate(
      tester,
      platform: _FakePlatform(),
      storage: _FakeStorage(),
      training: _training(
        TrainingItem(
          type: ItemType.exercise,
          name: 'Libre',
          isFreeDuration: true,
        ),
      ),
    );

    await tester.tap(find.text('Démarrer'));
    await tester.pumpAndSettle();

    expect(find.text('Suivre la séance en arrière-plan'), findsOneWidget);
  });

  testWidgets('une explication déjà présentée évite le dialogue', (
    tester,
  ) async {
    final storage = _FakeStorage()..presented = true;
    await _pumpGate(tester, platform: _FakePlatform(), storage: storage);

    await tester.tap(find.text('Démarrer'));
    await tester.pumpAndSettle();

    expect(find.text('Suivre la séance en arrière-plan'), findsNothing);
    expect(find.text('Lancements : 1'), findsOneWidget);
  });
}

Future<void> _pumpGate(
  WidgetTester tester, {
  required _FakePlatform platform,
  required _FakeStorage storage,
  Training? training,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: _GateHarness(
        gate: SessionStartPermissionGate(
          permissionService: SessionNotificationPermissionService(
            platform: platform,
          ),
          settingsStorage: storage,
        ),
        training:
            training ??
            _training(
              TrainingItem(
                type: ItemType.exercise,
                name: 'Temps',
                duration: const Duration(seconds: 20),
              ),
            ),
      ),
    ),
  );
}

Training _training(TrainingItem item) => _trainingItems([item]);

Training _trainingItems(List<TrainingItem> items) => Training(
  id: 'training',
  name: 'Séance',
  groups: [ExerciseGroup(id: 'group', name: 'Groupe', items: items)],
  createdAt: DateTime(2026),
);

class _GateHarness extends StatefulWidget {
  final SessionStartPermissionGate gate;
  final Training training;

  const _GateHarness({required this.gate, required this.training});

  @override
  State<_GateHarness> createState() => _GateHarnessState();
}

class _GateHarnessState extends State<_GateHarness> {
  int starts = 0;

  Future<void> _start() async {
    await widget.gate.prepare(context, widget.training);
    if (mounted) setState(() => starts++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          FilledButton(onPressed: _start, child: const Text('Démarrer')),
          Text('Lancements : $starts'),
        ],
      ),
    );
  }
}

class _FakeStorage implements SessionPermissionPromptStorage {
  bool presented = false;

  @override
  Future<bool> loadSessionNotificationExplanationPresented() async => presented;

  @override
  Future<void> saveSessionNotificationExplanationPresented(bool value) async {
    presented = value;
  }
}

class _FakePlatform implements SessionNotificationPermissionPlatform {
  _FakePlatform({
    this.notificationStatus = SessionNotificationPermissionStatus.denied,
  });

  SessionNotificationPermissionStatus notificationStatus;
  int notificationRequests = 0;
  int batteryRequests = 0;

  @override
  void initialize() {}

  @override
  Future<SessionNotificationPermissionStatus>
  notificationPermissionStatus() async => notificationStatus;

  @override
  Future<SessionNotificationPermissionStatus>
  requestNotificationPermission() async {
    notificationRequests++;
    notificationStatus = SessionNotificationPermissionStatus.granted;
    return notificationStatus;
  }

  @override
  Future<bool> openNotificationSettings() async => true;

  @override
  Future<BatteryOptimizationStatus> batteryOptimizationStatus() async =>
      BatteryOptimizationStatus.optimized;

  @override
  Future<void> requestBatteryOptimizationExemption() async {
    batteryRequests++;
  }
}
