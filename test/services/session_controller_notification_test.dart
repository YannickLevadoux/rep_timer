import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/notification_sound.dart';
import 'package:rep_timer/models/session_checkpoint.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/app_settings_storage.dart';
import 'package:rep_timer/services/session_checkpoint_storage.dart';
import 'package:rep_timer/services/session_controller.dart';
import 'package:rep_timer/services/session_notification_service.dart';
import 'package:rep_timer/services/step_end_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'un seuil sonore signalé plusieurs fois ne joue le son qu’une fois',
    () async {
      final stepEndService = _FakeStepEndNotificationService();
      final foregroundService = _FakeSessionNotificationService();
      final controller = _buildController(
        mode: NotificationMode.sound,
        stepEndService: stepEndService,
        foregroundService: foregroundService,
      );
      addTearDown(controller.dispose);

      await _flushAsyncInitialization();
      final stepToken = foregroundService.stepToken;

      foregroundService.signalSoundThreshold(stepToken);
      foregroundService.signalSoundThreshold(stepToken);
      await _flushAsyncInitialization();

      expect(stepEndService.soundCalls, 1);
    },
  );

  test(
    'les fins successives font progresser la séance en arrière-plan sans doublon',
    () async {
      final stepEndService = _FakeStepEndNotificationService();
      final foregroundService = _FakeSessionNotificationService();
      final controller = _buildController(
        mode: NotificationMode.vibration,
        stepEndService: stepEndService,
        foregroundService: foregroundService,
      );
      addTearDown(controller.dispose);

      await _flushAsyncInitialization();
      final firstStepToken = foregroundService.stepToken;
      controller.handleAppBackgrounded();

      foregroundService.signalStepEnded(
        firstStepToken,
        NotificationMode.vibration,
      );
      foregroundService.signalStepEnded(
        firstStepToken,
        NotificationMode.vibration,
      );
      await _flushAsyncInitialization();

      expect(stepEndService.vibrationCalls, 1);
      expect(controller.currentIndex, 1);

      foregroundService.signalStepEnded(
        firstStepToken,
        NotificationMode.vibration,
      );
      await _flushAsyncInitialization();

      expect(stepEndService.vibrationCalls, 1);
      expect(controller.currentIndex, 1);

      final secondStepToken = foregroundService.stepToken;
      foregroundService.signalStepEnded(
        secondStepToken,
        NotificationMode.vibration,
      );
      await _flushAsyncInitialization();

      expect(stepEndService.vibrationCalls, 2);
      expect(controller.currentIndex, 2);
    },
  );

  test('le son est réarmé après chaque fin en arrière-plan', () async {
    final stepEndService = _FakeStepEndNotificationService();
    final foregroundService = _FakeSessionNotificationService();
    final controller = _buildController(
      mode: NotificationMode.sound,
      stepEndService: stepEndService,
      foregroundService: foregroundService,
    );
    addTearDown(controller.dispose);

    await _flushAsyncInitialization();
    controller.handleAppBackgrounded();
    final firstStepToken = foregroundService.stepToken;

    foregroundService.signalSoundThreshold(firstStepToken);
    foregroundService.signalStepEnded(firstStepToken, NotificationMode.sound);
    await _flushAsyncInitialization();

    final secondStepToken = foregroundService.stepToken;
    foregroundService.signalSoundThreshold(secondStepToken);
    await _flushAsyncInitialization();

    expect(stepEndService.soundCalls, 2);
    expect(controller.currentIndex, 1);
    expect(secondStepToken, isNot(firstStepToken));
  });
}

SessionController _buildController({
  required NotificationMode mode,
  required _FakeStepEndNotificationService stepEndService,
  required _FakeSessionNotificationService foregroundService,
}) {
  final group = ExerciseGroup(
    id: 'group',
    name: 'Groupe',
    items: <TrainingItem>[
      TrainingItem(
        type: ItemType.exercise,
        name: 'Exercice 1',
        duration: const Duration(minutes: 1),
      ),
      TrainingItem(
        type: ItemType.exercise,
        name: 'Exercice 2',
        duration: const Duration(minutes: 1),
      ),
      TrainingItem(
        type: ItemType.exercise,
        name: 'Exercice 3',
        duration: const Duration(minutes: 1),
      ),
    ],
  );

  return SessionController(
    training: Training(
      id: 'training',
      name: 'Séance',
      groups: <ExerciseGroup>[group],
      createdAt: DateTime(2026),
    ),
    checkpointStorage: _FakeCheckpointStorage(),
    settingsStorage: _FakeSettingsStorage(mode),
    notificationService: stepEndService,
    foregroundNotificationService: foregroundService,
    enableWakelock: () async {},
    disableWakelock: () async {},
  );
}

Future<void> _flushAsyncInitialization() => Future<void>.delayed(Duration.zero);

class _FakeSettingsStorage extends AppSettingsStorage {
  final NotificationMode mode;

  _FakeSettingsStorage(this.mode);

  @override
  Future<NotificationMode> loadNotificationMode() async => mode;
}

class _FakeCheckpointStorage extends SessionCheckpointStorage {
  @override
  Future<void> saveCheckpoint(SessionCheckpoint checkpoint) async {}

  @override
  Future<void> clearCheckpoint() async {}
}

class _FakeStepEndNotificationService implements StepEndNotifier {
  int soundCalls = 0;
  int vibrationCalls = 0;

  @override
  Future<void> preload(NotificationSound sound) async {}

  @override
  Future<void> playCountdown(NotificationSound sound) async {
    soundCalls++;
  }

  @override
  Future<void> stopCountdown() async {}

  @override
  Future<void> vibrate() async {
    vibrationCalls++;
  }

  @override
  void dispose() {}
}

class _FakeSessionNotificationService extends SessionNotificationService {
  late String stepToken;
  late void Function(String stepToken) _onSoundThreshold;
  late void Function(String stepToken, NotificationMode mode) _onTimedStepEnded;

  @override
  Future<void> pin({
    required String stepLabel,
    required String nextStepLabel,
    required String stepToken,
    required NotificationMode notificationMode,
    required NotificationSound notificationSound,
    required bool isPlaying,
    required bool isCountingDown,
    required int baseMilliseconds,
    required void Function() onPausePressed,
    required void Function(String stepToken) onSoundThreshold,
    required void Function(String stepToken, NotificationMode mode)
    onTimedStepEnded,
  }) async {
    this.stepToken = stepToken;
    _onSoundThreshold = onSoundThreshold;
    _onTimedStepEnded = onTimedStepEnded;
  }

  void signalSoundThreshold(String stepToken) => _onSoundThreshold(stepToken);

  void signalStepEnded(String stepToken, NotificationMode mode) =>
      _onTimedStepEnded(stepToken, mode);

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}
