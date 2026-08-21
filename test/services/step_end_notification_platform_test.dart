import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/services/step_end_notification_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const audioChannel = MethodChannel('xyz.luan/audioplayers');
  const globalAudioChannel = MethodChannel('xyz.luan/audioplayers.global');
  const vibrationChannel = MethodChannel('vibration');

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(audioChannel, null);
    messenger.setMockMethodCallHandler(globalAudioChannel, null);
    messenger.setMockMethodCallHandler(vibrationChannel, null);
  });

  test('adapte la configuration et le cycle de vie audioplayers', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(audioChannel, (_) async => null);
    messenger.setMockMethodCallHandler(globalAudioChannel, (_) async => null);
    final audioPlayer = _FakeAudioPlayer();
    final player = AudioplayersStepEndAudioPlayer(audioPlayer);

    await player.setAudioContext(AudioContext());
    await player.setSource('sounds/reptimerSequence-3s.ogg');
    await player.play('sounds/reptimerSequence-3s.ogg');
    await player.playFrom(
      'sounds/reptimerSequence-3s.ogg',
      const Duration(milliseconds: 250),
    );
    await player.stop();
    await player.dispose();

    expect(audioPlayer.calls, <String>[
      'setAudioContext',
      'setSource:sounds/reptimerSequence-3s.ogg',
      'play:sounds/reptimerSequence-3s.ogg@null',
      'play:sounds/reptimerSequence-3s.ogg@250',
      'stop',
      'dispose',
    ]);
  });

  test('adapte la disponibilité et la durée de vibration', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(vibrationChannel, (call) async {
          calls.add(call);
          if (call.method == 'hasVibrator') return true;
          return null;
        });
    const platform = PluginStepEndVibrationPlatform();

    expect(await platform.hasVibrator(), isFalse);
    await platform.vibrate(duration: 300);

    expect(calls.map((call) => call.method), ['vibrate']);
  });
}

class _FakeAudioPlayer extends AudioPlayer {
  _FakeAudioPlayer() : super(playerId: 'step-end-platform-test');

  final calls = <String>[];

  @override
  Future<void> setAudioContext(AudioContext ctx) async {
    calls.add('setAudioContext');
  }

  @override
  Future<void> setSource(Source source) async {
    calls.add('setSource:${(source as AssetSource).path}');
  }

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    calls.add(
      'play:${(source as AssetSource).path}@${position?.inMilliseconds}',
    );
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }

  @override
  Future<void> dispose() async {
    calls.add('dispose');
  }
}
