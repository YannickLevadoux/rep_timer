import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/controllers/settings_preferences_controller.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/services/app_settings_storage.dart';
import 'package:rep_timer/services/step_end_notification_platform.dart';
import 'package:rep_timer/services/step_end_notification_service.dart';

void main() {
  test('charge, modifie et applique toutes les préférences', () async {
    final storage = _FakeSettingsStorage(
      prefillExerciseName: false,
      notificationMode: NotificationMode.vibration,
      countdownSeconds: 8,
    );
    final previewAudio = _FakeAudioPlayer();
    final vibration = _FakeVibrationPlatform();
    final controller = SettingsPreferencesController(
      storage,
      notificationService: StepEndNotificationService(
        countdownAudio: _FakeAudioPlayer(),
        previewAudio: previewAudio,
        vibrationPlatform: vibration,
      ),
    );
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.load();
    expect(controller.prefillExerciseName, isFalse);
    expect(controller.notificationMode, NotificationMode.vibration);
    expect(controller.preSessionCountdownSeconds, 8);

    await controller.setPrefillExerciseName(true);
    await controller.setPreSessionCountdownSeconds(12);
    controller.applyRestored(
      const ExportableAppSettings(
        themeMode: ThemeMode.dark,
        prefillExerciseName: false,
        notificationMode: NotificationMode.none,
        preSessionCountdownSeconds: 4,
      ),
    );

    expect(storage.savedPrefillExerciseName, isTrue);
    expect(storage.savedCountdownSeconds, 12);
    expect(controller.prefillExerciseName, isFalse);
    expect(controller.notificationMode, NotificationMode.none);
    expect(controller.preSessionCountdownSeconds, 4);
    expect(notifications, 4);
  });

  test('le cycle joue son, vibration, puis rien', () async {
    final previewAudio = _FakeAudioPlayer();
    final vibration = _FakeVibrationPlatform();
    final storage = _FakeSettingsStorage();
    final controller = SettingsPreferencesController(
      storage,
      notificationService: StepEndNotificationService(
        countdownAudio: _FakeAudioPlayer(),
        previewAudio: previewAudio,
        vibrationPlatform: vibration,
      ),
    );
    addTearDown(controller.dispose);

    await controller.cycleNotificationMode();
    await controller.cycleNotificationMode();
    await controller.cycleNotificationMode();

    expect(storage.savedNotificationModes, NotificationMode.values);
    expect(previewAudio.playCount, 1);
    expect(vibration.vibrationCount, 1);
    expect(controller.notificationMode, NotificationMode.none);
  });

  test('ignore un chargement terminé après dispose', () async {
    final storage = _FakeSettingsStorage()..blockLoad = Completer<void>();
    final controller = SettingsPreferencesController(
      storage,
      notificationService: StepEndNotificationService(
        countdownAudio: _FakeAudioPlayer(),
        previewAudio: _FakeAudioPlayer(),
        vibrationPlatform: _FakeVibrationPlatform(),
      ),
    );
    final load = controller.load();

    controller.dispose();
    storage.blockLoad!.complete();
    await load;

    expect(
      controller.prefillExerciseName,
      AppSettingsStorage.defaultPrefillExerciseName,
    );
  });
}

class _FakeSettingsStorage extends AppSettingsStorage {
  _FakeSettingsStorage({
    this.prefillExerciseName = AppSettingsStorage.defaultPrefillExerciseName,
    this.notificationMode = AppSettingsStorage.defaultNotificationMode,
    this.countdownSeconds =
        AppSettingsStorage.defaultPreSessionCountdownSeconds,
  });

  final bool prefillExerciseName;
  final NotificationMode notificationMode;
  final int countdownSeconds;
  Completer<void>? blockLoad;
  bool? savedPrefillExerciseName;
  int? savedCountdownSeconds;
  final savedNotificationModes = <NotificationMode>[];

  Future<void> _wait() => blockLoad?.future ?? Future<void>.value();

  @override
  Future<bool> loadPrefillExerciseName() async {
    await _wait();
    return prefillExerciseName;
  }

  @override
  Future<NotificationMode> loadNotificationMode() async {
    await _wait();
    return notificationMode;
  }

  @override
  Future<int> loadPreSessionCountdownSeconds() async {
    await _wait();
    return countdownSeconds;
  }

  @override
  Future<void> savePrefillExerciseName(bool value) async {
    savedPrefillExerciseName = value;
  }

  @override
  Future<void> saveNotificationMode(NotificationMode mode) async {
    savedNotificationModes.add(mode);
  }

  @override
  Future<void> savePreSessionCountdownSeconds(int value) async {
    savedCountdownSeconds = value;
  }
}

class _FakeAudioPlayer implements StepEndAudioPlayer {
  int playCount = 0;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> play(String assetPath) async => playCount++;

  @override
  Future<void> playFrom(String assetPath, Duration position) async {}

  @override
  Future<void> setAudioContext(AudioContext context) async {}

  @override
  Future<void> setSource(String assetPath) async {}

  @override
  Future<void> stop() async {}
}

class _FakeVibrationPlatform implements StepEndVibrationPlatform {
  int vibrationCount = 0;

  @override
  Future<bool?> hasVibrator() async => true;

  @override
  Future<void> vibrate({required int duration}) async => vibrationCount++;
}
