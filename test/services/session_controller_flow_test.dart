import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/notification_sound.dart';
import 'package:rep_timer/models/session_checkpoint.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/app_settings_storage.dart';
import 'package:rep_timer/services/session_checkpoint_storage.dart';
import 'package:rep_timer/services/session_controller.dart';
import 'package:rep_timer/services/session_notification_protocol.dart';
import 'package:rep_timer/services/session_notification_service.dart';
import 'package:rep_timer/services/step_end_notification_service.dart';
import 'package:rep_timer/services/training_history_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'pause, progression, saut et revue sauvegardent les transitions',
    () async {
      final harness = _Harness();
      final controller = harness.buildController();
      addTearDown(controller.dispose);
      await _flush();

      controller.togglePause();
      await _flush();
      expect(controller.paused, isTrue);
      expect(harness.checkpoints.saved.last.paused, isTrue);

      controller.togglePause();
      controller.completeCurrentStep();
      await _flush();
      expect(controller.currentIndex, 1);
      expect(controller.completed, [true, false, false]);
      expect(harness.checkpoints.saved.last.currentIndex, 1);

      controller.jumpToStep(2);
      controller.completeCurrentStep();
      await _flush();
      expect(controller.pendingIncompleteReview, isTrue);
      expect(controller.paused, isTrue);
      expect(harness.checkpoints.saved.last.completed, [true, false, true]);

      controller.jumpToStep(1);
      await _flush();
      expect(controller.pendingIncompleteReview, isFalse);
      expect(controller.paused, isFalse);
      expect(harness.checkpoints.saved.last.currentIndex, 1);
    },
  );

  test('la fin anticipée est idempotente et libère les ressources', () async {
    final harness = _Harness();
    final controller = harness.buildController();
    addTearDown(controller.dispose);
    await _flush();
    final stopCallsBeforeFinish = harness.foreground.stopCalls;

    await Future.wait([
      controller.finishSession(earlyExit: true),
      controller.finishSession(earlyExit: true),
    ]);
    await controller.finishSession(earlyExit: true);

    expect(controller.finished, isTrue);
    expect(harness.history.entries, hasLength(1));
    expect(
      harness.history.entries.single.status,
      TrainingSessionStatus.incomplete,
    );
    expect(harness.checkpoints.clearCalls, 1);
    expect(harness.foreground.stopCalls, stopCallsBeforeFinish + 1);
    expect(harness.disableWakelockCalls, 1);
  });

  test('abandonne le checkpoint et tolère les appels après dispose', () async {
    final harness = _Harness();
    final controller = harness.buildController();
    await _flush();

    await controller.abandon();
    expect(harness.checkpoints.clearCalls, 1);
    expect(harness.stepEnd.stopCalls, greaterThan(0));

    controller.dispose();
    expect(harness.disableWakelockCalls, 1);
    expect(() => controller.togglePause(), returnsNormally);
    expect(() => controller.dispose(), returnsNormally);
  });
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _Harness {
  final _FakeCheckpointStorage checkpoints = _FakeCheckpointStorage();
  final _FakeHistoryStorage history = _FakeHistoryStorage();
  final _FakeStepEndNotifier stepEnd = _FakeStepEndNotifier();
  final _FakeNotificationService foreground = _FakeNotificationService();
  int disableWakelockCalls = 0;

  SessionController buildController() => SessionController(
    training: Training(
      id: 'training',
      name: 'Séance',
      groups: [
        ExerciseGroup(
          id: 'group',
          name: 'Groupe',
          items: [
            for (var i = 1; i <= 3; i++)
              TrainingItem(
                type: ItemType.exercise,
                name: 'Exercice $i',
                repetitions: 5,
              ),
          ],
        ),
      ],
      createdAt: DateTime(2026),
    ),
    checkpointStorage: checkpoints,
    historyStorage: history,
    settingsStorage: _FakeSettingsStorage(),
    notificationService: stepEnd,
    foregroundNotificationService: foreground,
    enableWakelock: () async {},
    disableWakelock: () async => disableWakelockCalls++,
  );
}

class _FakeCheckpointStorage extends SessionCheckpointStorage {
  final List<SessionCheckpoint> saved = [];
  int clearCalls = 0;

  @override
  Future<void> saveCheckpoint(SessionCheckpoint checkpoint) async {
    saved.add(checkpoint);
  }

  @override
  Future<void> clearCheckpoint() async {
    clearCalls++;
  }
}

class _FakeHistoryStorage extends TrainingHistoryStorage {
  final List<TrainingHistoryEntry> entries = [];

  @override
  Future<void> addEntry(TrainingHistoryEntry entry) async {
    entries.add(entry);
  }
}

class _FakeSettingsStorage extends AppSettingsStorage {
  @override
  Future<NotificationMode> loadNotificationMode() async =>
      NotificationMode.none;
}

class _FakeStepEndNotifier implements StepEndNotifier {
  int stopCalls = 0;

  @override
  Future<void> preload(NotificationSound sound) async {}
  @override
  Future<void> playCountdown(NotificationSound sound) async {}
  @override
  Future<void> stopCountdown() async => stopCalls++;
  @override
  Future<void> vibrate() async {}
  @override
  void dispose() {}
}

class _FakeNotificationService extends SessionNotificationService {
  int stopCalls = 0;

  @override
  Future<void> pin({
    required SessionNotificationPinData data,
    required void Function() onPausePressed,
    required void Function(String stepToken) onSoundThreshold,
    required void Function(String stepToken, NotificationMode mode)
    onTimedStepEnded,
  }) async {}

  @override
  Future<void> stop() async => stopCalls++;
  @override
  void dispose() {}
}
