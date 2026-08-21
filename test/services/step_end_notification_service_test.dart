import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/notification_sound.dart';
import 'package:rep_timer/services/step_end_notification_platform.dart';
import 'package:rep_timer/services/step_end_notification_service.dart';

void main() {
  test('précharge, joue, arrête et lit un aperçu audio', () async {
    final countdown = _FakeAudioPlayer();
    final preview = _FakeAudioPlayer();
    final service = StepEndNotificationService(
      countdownAudio: countdown,
      previewAudio: preview,
      vibrationPlatform: _FakeVibrationPlatform(),
    );

    await service.preload(_sound);
    await service.playCountdown(_sound);
    await service.stopCountdown();
    await service.playPreview(_sound);

    expect(countdown.calls, <String>[
      'audio-context',
      'source:sounds/test.ogg',
      'stop',
      'play:sounds/test.ogg',
      'stop',
    ]);
    expect(preview.calls, <String>[
      'audio-context',
      'stop',
      'play:sounds/test.ogg',
    ]);
    expect(countdown.audioContexts, hasLength(1));
    expect(
      countdown.audioContexts.single.android.audioFocus,
      AndroidAudioFocus.gainTransientMayDuck,
    );
    expect(preview.audioContexts, hasLength(1));
    expect(
      preview.audioContexts.single.android.audioFocus,
      AndroidAudioFocus.gainTransientMayDuck,
    );
  });

  test('un nouvel aperçu interrompt le précédent avant de jouer', () async {
    final preview = _FakeAudioPlayer();
    final service = StepEndNotificationService(
      countdownAudio: _FakeAudioPlayer(),
      previewAudio: preview,
      vibrationPlatform: _FakeVibrationPlatform(),
    );

    await service.playPreview(_sound);
    await service.playPreview(_sound);

    expect(preview.calls, <String>[
      'audio-context',
      'stop',
      'play:sounds/test.ogg',
      'stop',
      'play:sounds/test.ogg',
    ]);
    expect(preview.audioContexts, hasLength(1));
  });

  test('joue séparément les signaux 3, 2, 1 et départ', () async {
    final countdown = _FakeAudioPlayer();
    final service = StepEndNotificationService(
      countdownAudio: countdown,
      previewAudio: _FakeAudioPlayer(),
      vibrationPlatform: _FakeVibrationPlatform(),
    );

    for (final seconds in [3, 2, 1, 0]) {
      await service.playPreparationSignal(_sound, seconds);
      await service.stopCountdown();
    }

    expect(countdown.calls, <String>[
      'audio-context',
      'stop',
      'play:sounds/test.ogg@0',
      'stop',
      'stop',
      'play:sounds/test.ogg@800',
      'stop',
      'stop',
      'play:sounds/test.ogg@1600',
      'stop',
      'stop',
      'play:sounds/test.ogg@2400',
      'stop',
    ]);
    service.dispose();
  });

  test('vibre uniquement lorsqu’un vibrateur est disponible', () async {
    final available = _FakeVibrationPlatform(available: true);
    final unavailable = _FakeVibrationPlatform(available: false);
    final availableService = _service(vibration: available);
    final unavailableService = _service(vibration: unavailable);

    await availableService.vibrate();
    await unavailableService.vibrate();

    expect(available.vibrationDurations, <int>[300]);
    expect(unavailable.vibrationDurations, isEmpty);
  });

  test('absorbe les erreurs audio et vibration', () async {
    final service = StepEndNotificationService(
      countdownAudio: _FakeAudioPlayer(throwOnCalls: true),
      previewAudio: _FakeAudioPlayer(throwOnCalls: true),
      vibrationPlatform: _FakeVibrationPlatform(throwOnCalls: true),
    );

    await service.preload(_sound);
    await service.playCountdown(_sound);
    await service.stopCountdown();
    await service.playPreview(_sound);
    await service.vibrate();
    service.dispose();
    await _flush();
  });

  test(
    'dispose libère les deux lecteurs et bloque tout nouvel appel plugin',
    () async {
      final countdown = _FakeAudioPlayer();
      final preview = _FakeAudioPlayer();
      final vibration = _FakeVibrationPlatform();
      final service = StepEndNotificationService(
        countdownAudio: countdown,
        previewAudio: preview,
        vibrationPlatform: vibration,
      );

      service.dispose();
      service.dispose();
      await _flush();
      await service.preload(_sound);
      await service.playCountdown(_sound);
      await service.stopCountdown();
      await service.playPreview(_sound);
      await service.vibrate();

      expect(countdown.calls, <String>['dispose']);
      expect(preview.calls, <String>['dispose']);
      expect(vibration.hasVibratorCalls, 0);
    },
  );
}

const _sound = NotificationSound(
  sequenceAsset: 'sounds/test.ogg',
  goOffset: Duration(milliseconds: 2400),
);

StepEndNotificationService _service({
  required _FakeVibrationPlatform vibration,
}) => StepEndNotificationService(
  countdownAudio: _FakeAudioPlayer(),
  previewAudio: _FakeAudioPlayer(),
  vibrationPlatform: vibration,
);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

class _FakeAudioPlayer implements StepEndAudioPlayer {
  _FakeAudioPlayer({this.throwOnCalls = false});

  final bool throwOnCalls;
  final calls = <String>[];
  final audioContexts = <AudioContext>[];

  void _record(String call) {
    calls.add(call);
    if (throwOnCalls) throw StateError(call);
  }

  @override
  Future<void> setAudioContext(AudioContext context) async {
    audioContexts.add(context);
    _record('audio-context');
  }

  @override
  Future<void> setSource(String assetPath) async =>
      _record('source:$assetPath');

  @override
  Future<void> play(String assetPath) async => _record('play:$assetPath');

  @override
  Future<void> playFrom(String assetPath, Duration position) async =>
      _record('play:$assetPath@${position.inMilliseconds}');

  @override
  Future<void> stop() async => _record('stop');

  @override
  Future<void> dispose() async => _record('dispose');
}

class _FakeVibrationPlatform implements StepEndVibrationPlatform {
  _FakeVibrationPlatform({this.available = false, this.throwOnCalls = false});

  final bool available;
  final bool throwOnCalls;
  int hasVibratorCalls = 0;
  final vibrationDurations = <int>[];

  @override
  Future<bool?> hasVibrator() async {
    hasVibratorCalls++;
    if (throwOnCalls) throw StateError('hasVibrator');
    return available;
  }

  @override
  Future<void> vibrate({required int duration}) async {
    if (throwOnCalls) throw StateError('vibrate');
    vibrationDurations.add(duration);
  }
}
