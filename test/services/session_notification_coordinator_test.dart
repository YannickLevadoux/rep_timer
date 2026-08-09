import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/notification_sound.dart';
import 'package:rep_timer/models/session_step.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/app_settings_storage.dart';
import 'package:rep_timer/services/session_notification_coordinator.dart';
import 'package:rep_timer/services/session_notification_protocol.dart';
import 'package:rep_timer/services/session_notification_service.dart';
import 'package:rep_timer/services/step_end_notification_service.dart';

void main() {
  test(
    'un choix utilisateur prime sur le chargement initial concurrent',
    () async {
      final initialMode = Completer<NotificationMode>();
      final harness = _Harness(initialMode.future);
      addTearDown(harness.dispose);

      harness.coordinator.start();
      harness.coordinator.cycleMode();
      initialMode.complete(NotificationMode.vibration);
      await _flush();

      expect(harness.coordinator.mode, NotificationMode.sound);
      expect(harness.modeChanges, 1);
      expect(
        harness.foreground.pins.last.notificationMode,
        NotificationMode.sound,
      );
    },
  );

  test('cycle les modes et notifie chaque changement', () async {
    final harness = _Harness(Future.value(NotificationMode.sound));
    addTearDown(harness.dispose);

    harness.coordinator.start();
    await _flush();
    harness.coordinator.cycleMode();
    harness.coordinator.cycleMode();
    harness.coordinator.cycleMode();

    expect(harness.coordinator.mode, NotificationMode.sound);
    expect(harness.modeChanges, 4);
    expect(
      harness.foreground.pins.map((data) => data.notificationMode),
      <NotificationMode>[
        NotificationMode.none,
        NotificationMode.sound,
        NotificationMode.vibration,
        NotificationMode.none,
        NotificationMode.sound,
      ],
    );
  });

  test('préserve pause, reprise, arrière-plan et premier plan', () async {
    final harness = _Harness(Future.value(NotificationMode.sound));
    addTearDown(harness.dispose);
    harness.coordinator.start();
    await _flush();
    final beforeBackground = harness.schedule.entries.last;

    harness.snapshot = _snapshot(backgrounded: true);
    harness.coordinator.handleAppBackgrounded();
    expect(beforeBackground.cancelled, isTrue);

    harness.snapshot = _snapshot();
    harness.coordinator.handleAppResumed();
    final afterResume = harness.schedule.entries.last;
    expect(afterResume.cancelled, isFalse);

    harness.snapshot = _snapshot(paused: true);
    harness.coordinator.handlePauseChanged();
    expect(afterResume.cancelled, isTrue);
    expect(harness.notifier.stopCalls, 1);
    expect(harness.foreground.pins.last.isPlaying, isFalse);

    harness.snapshot = _snapshot();
    harness.coordinator.handlePauseChanged();
    expect(harness.schedule.entries.last.cancelled, isFalse);
    expect(harness.foreground.pins.last.isPlaying, isTrue);
  });

  test(
    'réarme les changements manuel et naturel avec un nouveau token',
    () async {
      final harness = _Harness(Future.value(NotificationMode.sound));
      addTearDown(harness.dispose);
      harness.coordinator.start();
      await _flush();
      final firstToken = harness.foreground.pins.last.stepToken;

      harness.coordinator.prepareManualStepChange();
      harness.snapshot = _snapshot(index: 2, occurrence: 5);
      harness.coordinator.handleManualStepChanged();
      final manualToken = harness.foreground.pins.last.stepToken;

      harness.snapshot = _snapshot(index: 3, occurrence: 6);
      harness.coordinator.handleNaturalStepAdvanced();
      final naturalToken = harness.foreground.pins.last.stepToken;

      expect(harness.notifier.stopCalls, 1);
      expect(<String>{firstToken, manualToken, naturalToken}, hasLength(3));
      expect(harness.schedule.entries.last.cancelled, isFalse);
    },
  );

  test('arrêt et libération sont idempotents', () async {
    final harness = _Harness(Future.value(NotificationMode.none));

    await harness.coordinator.stop();
    await harness.coordinator.stop(cancelSound: true);
    harness.coordinator.dispose();
    harness.coordinator.dispose();
    await _flush();

    expect(harness.foreground.stopCalls, 1);
    expect(harness.foreground.disposeCalls, 1);
    expect(harness.notifier.disposeCalls, 1);
    expect(harness.notifier.stopCalls, 1);
  });
}

class _Harness {
  _Harness(Future<NotificationMode> initialMode)
    : settings = _FakeSettingsStorage(initialMode) {
    coordinator = SessionNotificationCoordinator(
      settingsStorage: settings,
      stepEndNotifier: notifier,
      notificationSound: _sound,
      foregroundService: foreground,
      snapshotProvider: () => snapshot,
      onPausePressed: () => pausePresses++,
      onTimedStepEnded: () => timedStepEnds++,
      onModeChanged: () => modeChanges++,
      now: () => DateTime.utc(2026, 8, 9, 10, 30),
      schedule: schedule.call,
    );
  }

  final _FakeSettingsStorage settings;
  final notifier = _FakeStepEndNotifier();
  final foreground = _FakeForegroundService();
  final schedule = _FakeSchedule();
  late final SessionNotificationCoordinator coordinator;
  SessionNotificationSnapshot snapshot = _snapshot();
  int pausePresses = 0;
  int timedStepEnds = 0;
  int modeChanges = 0;

  Future<void> dispose() async {
    coordinator.dispose();
    await _flush();
  }
}

const _sound = NotificationSound(
  sequenceAsset: 'sound.ogg',
  goOffset: Duration(milliseconds: 2400),
);

SessionNotificationSnapshot _snapshot({
  int index = 1,
  int occurrence = 3,
  bool paused = false,
  bool backgrounded = false,
}) => SessionNotificationSnapshot(
  currentStep: SessionStep(
    group: ExerciseGroup(id: 'group', name: 'Groupe', items: const []),
    roundIndex: 1,
    totalRounds: 1,
    item: TrainingItem(
      type: ItemType.exercise,
      name: 'Exercice',
      duration: const Duration(seconds: 10),
    ),
  ),
  nextStep: null,
  currentIndex: index,
  stepOccurrence: occurrence,
  stepElapsed: Duration.zero,
  paused: paused,
  finished: false,
  isAppBackgrounded: backgrounded,
);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _FakeSettingsStorage extends AppSettingsStorage {
  _FakeSettingsStorage(this.initialMode);

  final Future<NotificationMode> initialMode;

  @override
  Future<NotificationMode> loadNotificationMode() => initialMode;
}

class _FakeSchedule {
  final entries = <_Scheduled>[];

  void Function() call(Duration delay, void Function() callback) {
    final entry = _Scheduled(delay);
    entries.add(entry);
    return () => entry.cancelled = true;
  }
}

class _Scheduled {
  _Scheduled(this.delay);

  final Duration delay;
  bool cancelled = false;
}

class _FakeStepEndNotifier implements StepEndNotifier {
  int stopCalls = 0;
  int disposeCalls = 0;

  @override
  Future<void> preload(NotificationSound sound) async {}

  @override
  Future<void> playCountdown(NotificationSound sound) async {}

  @override
  Future<void> stopCountdown() async => stopCalls++;

  @override
  Future<void> vibrate() async {}

  @override
  void dispose() => disposeCalls++;
}

class _FakeForegroundService extends SessionNotificationService {
  final pins = <SessionNotificationPinData>[];
  int stopCalls = 0;
  int disposeCalls = 0;

  @override
  Future<void> pin({
    required SessionNotificationPinData data,
    required void Function() onPausePressed,
    required void Function(String stepToken) onSoundThreshold,
    required void Function(String stepToken, NotificationMode mode)
    onTimedStepEnded,
  }) async => pins.add(data);

  @override
  Future<void> stop() async => stopCalls++;

  @override
  void dispose() => disposeCalls++;
}
