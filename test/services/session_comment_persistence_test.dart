import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_type.dart';
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
import 'package:rep_timer/services/training_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'une séance classique modifie, notifie et persiste le commentaire',
    () async {
      final trainingStorage = _FakeTrainingStorage();
      final controller = _buildController(trainingStorage: trainingStorage);
      addTearDown(controller.dispose);
      await _flushInitialization();

      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.updateComment('Charge lourde');

      expect(controller.currentStep.item.comment, 'Charge lourde');
      expect(notifications, 1);
      expect(trainingStorage.savedTrainings, <Training>[controller.training]);
      expect(
        controller.trainingChangesPersistence,
        TrainingChangesPersistence.persistent,
      );
    },
  );

  test('une séance temporaire modifie et notifie sans persister', () async {
    final trainingStorage = _FakeTrainingStorage();
    final controller = _buildController(
      trainingStorage: trainingStorage,
      persistence: TrainingChangesPersistence.memoryOnly,
    );
    addTearDown(controller.dispose);
    await _flushInitialization();

    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.updateComment('Rythme soutenu');

    expect(controller.currentStep.item.comment, 'Rythme soutenu');
    expect(notifications, 1);
    expect(trainingStorage.savedTrainings, isEmpty);

    controller.goToNext();
    controller.goToPrevious();

    expect(controller.currentStep.item.comment, 'Rythme soutenu');
    expect(trainingStorage.savedTrainings, isEmpty);
  });

  test('une séance temporaire terminée conserve le commentaire dans '
      'l’historique', () async {
    final trainingStorage = _FakeTrainingStorage();
    final historyStorage = _FakeHistoryStorage();
    final controller = _buildController(
      trainingStorage: trainingStorage,
      historyStorage: historyStorage,
      persistence: TrainingChangesPersistence.memoryOnly,
    );
    addTearDown(controller.dispose);
    await _flushInitialization();

    await controller.updateComment('Bonne intensité');
    await controller.finishSession(earlyExit: true);

    expect(trainingStorage.savedTrainings, isEmpty);
    expect(historyStorage.entries, hasLength(1));
    expect(
      historyStorage.entries.single.steps.first.comment,
      'Bonne intensité',
    );
  });

  test('un exercice variable persiste le commentaire sur sa source', () async {
    final trainingStorage = _FakeTrainingStorage();
    final training = Training(
      id: 'variable-training',
      name: 'Variable',
      groups: [
        ExerciseGroup(
          id: 'variable',
          name: 'Pyramide',
          type: GroupType.variableRepetitions,
          repetitionSequence: [10, 12],
          items: [
            TrainingItem(
              type: ItemType.exercise,
              name: 'Squats',
              repetitions: 5,
            ),
          ],
        ),
      ],
      createdAt: DateTime(2026),
    );
    final controller = SessionController(
      training: training,
      trainingStorage: trainingStorage,
      checkpointStorage: _FakeCheckpointStorage(),
      historyStorage: _FakeHistoryStorage(),
      settingsStorage: _FakeSettingsStorage(),
      notificationService: _FakeStepEndNotifier(),
      foregroundNotificationService: _FakeNotificationService(),
      enableWakelock: () async {},
      disableWakelock: () async {},
    );
    addTearDown(controller.dispose);
    await _flushInitialization();

    await controller.updateComment('Technique propre');

    expect(training.groups.single.items.single.comment, 'Technique propre');
    expect(
      controller.steps.map((step) => step.item.comment),
      everyElement('Technique propre'),
    );
    expect(trainingStorage.savedTrainings, [training]);
    expect(controller.steps.map((step) => step.item.repetitions), [10, 12]);
  });
}

SessionController _buildController({
  required _FakeTrainingStorage trainingStorage,
  _FakeHistoryStorage? historyStorage,
  TrainingChangesPersistence persistence =
      TrainingChangesPersistence.persistent,
}) {
  final training = Training(
    id: 'training',
    name: 'Séance',
    groups: <ExerciseGroup>[
      ExerciseGroup(
        id: 'group',
        name: 'Groupe',
        items: <TrainingItem>[
          TrainingItem(
            type: ItemType.exercise,
            name: 'Exercice 1',
            repetitions: 10,
          ),
          TrainingItem(
            type: ItemType.exercise,
            name: 'Exercice 2',
            repetitions: 10,
          ),
        ],
      ),
    ],
    createdAt: DateTime(2026),
  );

  return SessionController(
    training: training,
    trainingChangesPersistence: persistence,
    trainingStorage: trainingStorage,
    checkpointStorage: _FakeCheckpointStorage(),
    historyStorage: historyStorage ?? _FakeHistoryStorage(),
    settingsStorage: _FakeSettingsStorage(),
    notificationService: _FakeStepEndNotifier(),
    foregroundNotificationService: _FakeNotificationService(),
    enableWakelock: () async {},
    disableWakelock: () async {},
  );
}

Future<void> _flushInitialization() => Future<void>.delayed(Duration.zero);

class _FakeTrainingStorage extends TrainingStorage {
  final List<Training> savedTrainings = <Training>[];

  @override
  Future<void> addOrUpdateTraining(Training training) async {
    savedTrainings.add(training);
  }
}

class _FakeHistoryStorage extends TrainingHistoryStorage {
  final List<TrainingHistoryEntry> entries = <TrainingHistoryEntry>[];

  @override
  Future<void> addEntry(TrainingHistoryEntry entry) async {
    entries.add(entry);
  }
}

class _FakeCheckpointStorage extends SessionCheckpointStorage {
  @override
  Future<void> saveCheckpoint(SessionCheckpoint checkpoint) async {}

  @override
  Future<void> clearCheckpoint() async {}
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
