import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/notification_sound.dart';
import 'package:rep_timer/models/session_checkpoint.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/services/app_settings_storage.dart';
import 'package:rep_timer/services/session_checkpoint_storage.dart';
import 'package:rep_timer/services/session_controller.dart';
import 'package:rep_timer/services/session_controller_base.dart';
import 'package:rep_timer/services/session_notification_protocol.dart';
import 'package:rep_timer/services/session_notification_service.dart';
import 'package:rep_timer/services/step_end_notification_service.dart';
import 'package:rep_timer/services/training_history_storage.dart';

class TimedSessionHarness {
  TimedSessionHarness(this.training, {this.mode = NotificationMode.none});

  final Training training;
  final NotificationMode mode;
  final checkpoints = FakeCheckpointStorage();
  final history = FakeHistoryStorage();
  final notifier = FakeStepEndNotifier();
  final foreground = FakeForegroundService();
  DateTime time = DateTime(2026);
  void Function()? tick;

  SessionController build({
    SessionCheckpoint? checkpoint,
    int countdownSeconds = 0,
  }) => SessionController(
    training: training,
    initialCheckpoint: checkpoint,
    checkpointStorage: checkpoints,
    historyStorage: history,
    settingsStorage: FakeSettingsStorage(mode),
    notificationService: notifier,
    foregroundNotificationService: foreground,
    enableWakelock: () async {},
    disableWakelock: () async {},
    now: () => time,
    tickSchedule: _schedule,
    preSessionCountdownSeconds: countdownSeconds,
  );

  SessionTickCancel _schedule(void Function() callback) {
    tick = callback;
    return () => tick = null;
  }

  void advance(Duration duration) {
    time = time.add(duration);
    tick?.call();
  }
}

class FakeCheckpointStorage extends SessionCheckpointStorage {
  final List<SessionCheckpoint> saved = [];
  int clearCalls = 0;
  @override
  Future<void> saveCheckpoint(SessionCheckpoint checkpoint) async =>
      saved.add(checkpoint);
  @override
  Future<void> clearCheckpoint() async => clearCalls++;
}

class FakeHistoryStorage extends TrainingHistoryStorage {
  final List<TrainingHistoryEntry> entries = [];
  @override
  Future<void> addEntry(TrainingHistoryEntry entry) async => entries.add(entry);
}

class FakeSettingsStorage extends AppSettingsStorage {
  FakeSettingsStorage(this.mode);
  final NotificationMode mode;
  @override
  Future<NotificationMode> loadNotificationMode() async => mode;
}

class FakeStepEndNotifier implements StepEndNotifier {
  int soundCalls = 0;
  int vibrationCalls = 0;
  @override
  Future<void> preload(NotificationSound sound) async {}
  @override
  Future<void> playCountdown(NotificationSound sound) async => soundCalls++;
  @override
  Future<void> stopCountdown() async {}
  @override
  Future<void> vibrate() async => vibrationCalls++;
  @override
  void dispose() {}
}

class FakeForegroundService extends SessionNotificationService {
  int pinCalls = 0;
  @override
  Future<void> pin({
    required SessionNotificationPinData data,
    required void Function() onPausePressed,
    required void Function(String) onSoundThreshold,
    required void Function(String, NotificationMode) onTimedStepEnded,
  }) async => pinCalls++;
  @override
  Future<void> stop() async {}
  @override
  void dispose() {}
}
