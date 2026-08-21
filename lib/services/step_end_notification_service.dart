import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../models/notification_sound.dart';
import 'step_end_notification_platform.dart';

/// Lecture audio/vibration des notifications de fin d'exercice/pause.
/// Ne connaît aucune logique temporelle (quand déclencher, quand
/// annuler) ni aucun mode : le TaskHandler du Foreground Service et le
/// filet de sécurité de [SessionController] l'appellent au bon moment ;
/// `SettingsScreen` l'utilise aussi pour les aperçus. Ce service sait
/// seulement "comment" jouer un son ou vibrer, jamais "quand" ni
/// "quel thème par défaut".
abstract interface class StepEndNotifier {
  Future<void> preload(NotificationSound sound);
  Future<void> playCountdown(NotificationSound sound);
  Future<void> stopCountdown();
  Future<void> vibrate();
  void dispose();
}

abstract interface class PreSessionSoundNotifier {
  Future<void> playPreparationSignal(
    NotificationSound sound,
    int secondsRemaining,
  );
}

class StepEndNotificationService
    implements StepEndNotifier, PreSessionSoundNotifier {
  static const _vibrationDurationMs = 300;
  static const _preparationSignalDuration = Duration(milliseconds: 650);
  static final _notificationAudioContext = AudioContext(
    android: const AudioContextAndroid(
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
  );

  // Lecteur dédié à la séquence "3-2-1-GO" pendant une séance. Un seul
  // fichier composite par déclenchement ne nécessite plus le pool de
  // lecteurs alternés utilisé par l'ancienne approche multi-fichiers.
  final StepEndAudioPlayer _countdownPlayer;

  // Lecteur séparé pour les aperçus (écran Paramètres) : les isoler du
  // lecteur de séance évite toute interférence entre les deux, et rend
  // chacun plus simple à raisonner indépendamment.
  final StepEndAudioPlayer _previewPlayer;

  final StepEndVibrationPlatform _vibrationPlatform;

  bool _disposed = false;
  Timer? _preparationStopTimer;
  Future<void>? _countdownAudioConfiguration;
  Future<void>? _previewAudioConfiguration;

  StepEndNotificationService({
    AudioPlayer? countdownPlayer,
    AudioPlayer? previewPlayer,
    StepEndAudioPlayer? countdownAudio,
    StepEndAudioPlayer? previewAudio,
    StepEndVibrationPlatform? vibrationPlatform,
  }) : assert(countdownPlayer == null || countdownAudio == null),
       assert(previewPlayer == null || previewAudio == null),
       _countdownPlayer =
           countdownAudio ?? AudioplayersStepEndAudioPlayer(countdownPlayer),
       _previewPlayer =
           previewAudio ?? AudioplayersStepEndAudioPlayer(previewPlayer),
       _vibrationPlatform =
           vibrationPlatform ?? const PluginStepEndVibrationPlatform();

  /// Précharge la source audio de [sound] à l'avance (typiquement une
  /// fois au démarrage d'une séance), pour réduire la latence de la
  /// toute première lecture réelle. Best-effort : une erreur ici ne
  /// doit jamais empêcher la lecture ultérieure via [playCountdown],
  /// qui rechargera la source si besoin.
  @override
  Future<void> preload(NotificationSound sound) async {
    if (_disposed) return;
    try {
      await _configureCountdownAudio();
      await _countdownPlayer.setSource(sound.sequenceAsset);
    } catch (_) {
      // Ignoré : la lecture réelle rechargera la source elle-même.
    }
  }

  /// Joue la séquence composite de [sound] (bips + GO) depuis le début.
  /// Appelé une seule fois par [SessionController] lorsque le point de
  /// déclenchement (T - [NotificationSound.goOffset]) est atteint.
  @override
  Future<void> playCountdown(NotificationSound sound) async {
    if (_disposed) return;
    try {
      await _configureCountdownAudio();
      await _countdownPlayer.stop();
      await _countdownPlayer.play(sound.sequenceAsset);
    } catch (_) {
      // Lecture best-effort : une erreur de lecture audio ne doit
      // jamais faire planter la séance en cours.
    }
  }

  /// Arrête immédiatement la séquence en cours (si elle joue), sans
  /// effet si rien n'est en train de jouer.
  @override
  Future<void> stopCountdown() async {
    if (_disposed) return;
    _preparationStopTimer?.cancel();
    _preparationStopTimer = null;
    try {
      await _countdownPlayer.stop();
    } catch (_) {}
  }

  @override
  Future<void> playPreparationSignal(
    NotificationSound sound,
    int secondsRemaining,
  ) async {
    if (_disposed || secondsRemaining < 0 || secondsRemaining > 3) return;
    _preparationStopTimer?.cancel();
    final position = Duration(
      microseconds: sound.goOffset.inMicroseconds * (3 - secondsRemaining) ~/ 3,
    );
    try {
      await _configureCountdownAudio();
      await _countdownPlayer.stop();
      await _countdownPlayer.playFrom(sound.sequenceAsset, position);
      _preparationStopTimer = Timer(
        _preparationSignalDuration,
        () => unawaited(stopCountdown()),
      );
    } catch (_) {}
  }

  /// Aperçu joué depuis l'écran Paramètres : lit une fois le fichier
  /// composite complet de [sound]. Un nouvel appel interrompt
  /// immédiatement un aperçu déjà en cours (lecteur dédié, toujours
  /// stoppé avant de rejouer) plutôt que de superposer plusieurs
  /// aperçus lors d'appuis rapides.
  Future<void> playPreview(NotificationSound sound) async {
    if (_disposed) return;
    try {
      await _configurePreviewAudio();
      await _previewPlayer.stop();
      await _previewPlayer.play(sound.sequenceAsset);
    } catch (_) {}
  }

  /// Vibration ponctuelle. Utilise le package `vibration` (Vibrator
  /// Android natif) plutôt que HapticFeedback.vibrate() : ce dernier
  /// respecte le réglage système "Retour haptique tactile" (celui du
  /// clavier/boutons) et non le moteur de vibration général — sur de
  /// nombreux appareils où ce réglage est désactivé, HapticFeedback ne
  /// produit alors aucune vibration perceptible, silencieusement.
  @override
  Future<void> vibrate() async {
    if (_disposed) return;
    try {
      final hasVibrator = await _vibrationPlatform.hasVibrator();
      if (hasVibrator == true) {
        await _vibrationPlatform.vibrate(duration: _vibrationDurationMs);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _preparationStopTimer?.cancel();
    unawaited(_disposePlayer(_countdownPlayer));
    unawaited(_disposePlayer(_previewPlayer));
  }

  Future<void> _disposePlayer(StepEndAudioPlayer player) async {
    try {
      await player.dispose();
    } catch (_) {}
  }

  Future<void> _configureCountdownAudio() => _countdownAudioConfiguration ??=
      _countdownPlayer.setAudioContext(_notificationAudioContext);

  Future<void> _configurePreviewAudio() => _previewAudioConfiguration ??=
      _previewPlayer.setAudioContext(_notificationAudioContext);
}
