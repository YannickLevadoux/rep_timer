import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/models/notification_sound.dart';
import 'package:rep_timer/services/pre_session_signal_coordinator.dart';
import 'package:rep_timer/services/step_end_notification_service.dart';

void main() {
  test('diffère le signal jusqu’au chargement du mode', () async {
    final notifier = _Notifier();
    var mode = NotificationMode.sound;
    final coordinator = _coordinator(notifier, () => mode);

    coordinator.emit(3);
    expect(notifier.sounds, 0);
    coordinator.markModeReady();
    await _flush();
    expect(notifier.sounds, 1);

    coordinator.emit(3);
    coordinator.emit(2);
    await _flush();
    expect(notifier.sounds, 2);

    mode = NotificationMode.vibration;
    coordinator.emit(1);
    await _flush();
    expect(notifier.vibrations, 1);
  });

  test('une pause supprime tout signal encore différé', () async {
    final notifier = _Notifier();
    final coordinator = _coordinator(notifier, () => NotificationMode.sound);

    coordinator.emit(3);
    coordinator.stop();
    coordinator.markModeReady();
    await _flush();

    expect(notifier.sounds, 0);
    expect(notifier.stops, 1);
  });
}

PreSessionSignalCoordinator _coordinator(
  _Notifier notifier,
  NotificationMode Function() mode,
) => PreSessionSignalCoordinator(
  modeProvider: mode,
  notifier: notifier,
  sound: NotificationSound.classic,
);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _Notifier implements StepEndNotifier {
  int sounds = 0;
  int vibrations = 0;
  int stops = 0;

  @override
  Future<void> playCountdown(NotificationSound sound) async => sounds++;
  @override
  Future<void> preload(NotificationSound sound) async {}
  @override
  Future<void> stopCountdown() async => stops++;
  @override
  Future<void> vibrate() async => vibrations++;
  @override
  void dispose() {}
}
