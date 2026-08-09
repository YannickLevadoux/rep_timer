import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/session_controller_composition.dart';
import 'package:rep_timer/services/session_notification_protocol.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'compose une reprise et sauvegarde son état via les fakes injectés',
    () async {
      final checkpoints = _FakeCheckpointStorage();
      final history = _FakeHistoryStorage();
      final checkpoint = SessionCheckpoint(
        trainingId: 'training',
        currentIndex: 1,
        completed: [true, false],
        globalElapsed: const Duration(seconds: 18),
        stepElapsed: const Duration(seconds: 3),
        paused: true,
        savedAt: DateTime(2026),
        stepActualDurations: const [Duration(seconds: 15), Duration.zero],
      );

      final composition = SessionControllerComposition(
        training: _training(),
        initialCheckpoint: checkpoint,
        checkpointStorage: checkpoints,
        historyStorage: history,
        settingsStorage: _FakeSettingsStorage(),
        notificationService: _FakeStepEndNotifier(),
        foregroundNotificationService: _FakeNotificationService(),
        enableWakelock: () async {},
        disableWakelock: () async {},
      );

      expect(composition.progress.restoredFromCheckpoint, isTrue);
      expect(composition.progress.currentIndex, 1);
      expect(composition.clock.paused, isTrue);
      expect(composition.clock.globalElapsed, const Duration(seconds: 18));

      await composition.saveCheckpoint();
      expect(checkpoints.saved!.currentIndex, 1);
      expect(checkpoints.saved!.stepElapsed, const Duration(seconds: 3));

      await composition.completeSession();
      expect(history.entries.single.status, TrainingSessionStatus.incomplete);
      expect(checkpoints.clearCalls, 1);
    },
  );
}

Training _training() => Training(
  id: 'training',
  name: 'Séance',
  groups: [
    ExerciseGroup(
      id: 'group',
      name: 'Groupe',
      items: [
        TrainingItem(type: ItemType.exercise, name: 'Un', repetitions: 5),
        TrainingItem(type: ItemType.exercise, name: 'Deux', repetitions: 5),
      ],
    ),
  ],
  createdAt: DateTime(2026),
);

class _FakeCheckpointStorage extends SessionCheckpointStorage {
  SessionCheckpoint? saved;
  int clearCalls = 0;

  @override
  Future<void> saveCheckpoint(SessionCheckpoint checkpoint) async {
    saved = checkpoint;
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
  @override
  Future<void> preload(NotificationSound sound) async {}
  @override
  Future<void> playCountdown(NotificationSound sound) async {}
  @override
  Future<void> stopCountdown() async {}
  @override
  Future<void> vibrate() async {}
  @override
  void dispose() {}
}

class _FakeNotificationService extends SessionNotificationService {
  @override
  Future<void> pin({
    required SessionNotificationPinData data,
    required void Function() onPausePressed,
    required void Function(String stepToken) onSoundThreshold,
    required void Function(String stepToken, NotificationMode mode)
    onTimedStepEnded,
  }) async {}

  @override
  Future<void> stop() async {}
  @override
  void dispose() {}
}
