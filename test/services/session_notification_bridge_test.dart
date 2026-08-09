import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/notification_sound.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/app_settings_storage.dart';
import 'package:rep_timer/services/session_clock.dart';
import 'package:rep_timer/services/session_notification_bridge.dart';
import 'package:rep_timer/services/session_notification_protocol.dart';
import 'package:rep_timer/services/session_notification_service.dart';
import 'package:rep_timer/services/session_progress_state.dart';
import 'package:rep_timer/services/step_end_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('traduit progression et horloge en données de notification', () async {
    final progress = SessionProgressState(training: _training());
    final clock = SessionClock(
      initialStepElapsed: const Duration(seconds: 4),
      initiallyPaused: true,
    );
    final foreground = _FakeNotificationService();
    final bridge = SessionNotificationBridge(
      progress: progress,
      clock: clock,
      settingsStorage: _FakeSettingsStorage(),
      stepEndNotifier: _FakeStepEndNotifier(),
      notificationSound: NotificationSound.classic,
      foregroundService: foreground,
      onPausePressed: () {},
      onTimedStepEnded: () {},
      onModeChanged: () {},
    );
    addTearDown(bridge.dispose);

    bridge.start();
    await Future<void>.delayed(Duration.zero);

    expect(foreground.data.stepLabel, 'Un');
    expect(foreground.data.nextStepLabel, 'Suivant : Groupe - Deux');
    expect(foreground.data.isPlaying, isFalse);
    expect(foreground.data.baseMilliseconds, 6000);

    progress.completeCurrentStep();
    clock.resetStep();
    bridge.handleNaturalStepAdvanced();

    expect(foreground.data.stepLabel, 'Deux');
    expect(foreground.data.nextStepLabel, 'Fin de la séance');
  });
}

Training _training() => Training(
  id: 'training',
  name: 'Séance',
  groups: [
    ExerciseGroup(
      id: 'group',
      name: 'Groupe',
      items: [
        TrainingItem(
          type: ItemType.exercise,
          name: 'Un',
          duration: const Duration(seconds: 10),
        ),
        TrainingItem(
          type: ItemType.exercise,
          name: 'Deux',
          duration: const Duration(seconds: 20),
        ),
      ],
    ),
  ],
  createdAt: DateTime(2026),
);

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
  late SessionNotificationPinData data;

  @override
  Future<void> pin({
    required SessionNotificationPinData data,
    required void Function() onPausePressed,
    required void Function(String stepToken) onSoundThreshold,
    required void Function(String stepToken, NotificationMode mode)
    onTimedStepEnded,
  }) async {
    this.data = data;
  }

  @override
  Future<void> stop() async {}
  @override
  void dispose() {}
}
