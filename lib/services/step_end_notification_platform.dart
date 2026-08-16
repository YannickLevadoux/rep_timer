import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

/// Lecteur audio minimal utilisé par les notifications de fin d'étape.
abstract interface class StepEndAudioPlayer {
  Future<void> setSource(String assetPath);
  Future<void> play(String assetPath);
  Future<void> playFrom(String assetPath, Duration position);
  Future<void> stop();
  Future<void> dispose();
}

class AudioplayersStepEndAudioPlayer implements StepEndAudioPlayer {
  AudioplayersStepEndAudioPlayer([AudioPlayer? player])
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> setSource(String assetPath) =>
      _player.setSource(AssetSource(assetPath));

  @override
  Future<void> play(String assetPath) => _player.play(AssetSource(assetPath));

  @override
  Future<void> playFrom(String assetPath, Duration position) =>
      _player.play(AssetSource(assetPath), position: position);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

/// Frontière minimale autour des appels statiques du plugin de vibration.
abstract interface class StepEndVibrationPlatform {
  Future<bool?> hasVibrator();
  Future<void> vibrate({required int duration});
}

class PluginStepEndVibrationPlatform implements StepEndVibrationPlatform {
  const PluginStepEndVibrationPlatform();

  @override
  Future<bool?> hasVibrator() => Vibration.hasVibrator();

  @override
  Future<void> vibrate({required int duration}) =>
      Vibration.vibrate(duration: duration);
}
