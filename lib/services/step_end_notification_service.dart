import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

import '../models/notification_mode.dart';

/// Point d'entrée unique pour jouer les notifications de fin
/// d'exercice/pause (mode Son ou Vibration), ainsi que leurs aperçus
/// depuis l'écran Paramètres. Isolé du [SessionController] et de
/// `SettingsScreen` pour que la logique de lecture audio/vibration ne
/// soit écrite qu'à un seul endroit.
///
/// Les fichiers son doivent être copiés dans `assets/sounds/` à la
/// racine du projet :
/// - `assets/sounds/correct-bell.ogg`
/// - `assets/sounds/deadrobotmusic.ogg`
/// et déclarés dans le `pubspec.yaml` sous `flutter: assets:` (voir la
/// documentation fournie avec cette fonctionnalité).
class StepEndNotificationService {
  static const _bellAsset = 'sounds/correct-bell.ogg';
  static const _goAsset = 'sounds/deadrobotmusic.ogg';

  // Durée de la vibration, en millisecondes.
  static const _vibrationDurationMs = 300;

  // Pool de lecteurs alternés (voir _playOnNextPlayer) : chaque son est
  // joué sur un lecteur différent du précédent, ce qui évite les ratés
  // de lecture liés à la réutilisation d'un même AudioPlayer en
  // succession rapide (.play() sur une source qu'il vient déjà de jouer
  // peut être silencieusement ignoré), sans le défaut d'un .stop()
  // préalable : une micro-coupure audible du son en cours, gênante au
  // casque.
  final List<AudioPlayer> _players;
  int _nextPlayerIndex = 0;

  StepEndNotificationService({List<AudioPlayer>? players})
    : _players = players ?? List.generate(3, (_) => AudioPlayer());

  /// Appelé à chaque tick (1 Hz) du chronomètre d'une étape à durée
  /// (pause ou exercice Temps) avec le temps restant en secondes
  /// entières — la même valeur que celle affichée à l'écran, ce qui
  /// garantit la synchronisation par construction. Ne déclenche quelque
  /// chose qu'aux instants 3/2/1/0 secondes ; toute autre valeur (y
  /// compris négative, en cas de léger dépassement) est ignorée.
  ///
  /// Mode Son : bip à 3, 2 et 1 seconde, puis son de fin à 0. Mode
  /// Vibration : une seule vibration, à 0 seconde uniquement (voir la
  /// spec : la vibration ne "compte" pas 3-2-1 comme le son).
  Future<void> onTick({
    required NotificationMode mode,
    required int remainingSeconds,
  }) async {
    if (mode == NotificationMode.none) return;
    if (remainingSeconds > 3 || remainingSeconds < 0) return;

    if (mode == NotificationMode.vibration) {
      if (remainingSeconds == 0) await _vibrate();
      return;
    }

    if (remainingSeconds == 0) {
      await _playGoSound();
    } else {
      await _playBellSound();
    }
  }

  /// Aperçu joué depuis l'écran Paramètres au moment où l'utilisateur
  /// sélectionne un mode (jamais pendant une séance, et jamais pour le
  /// mode Rien).
  Future<void> playPreview(NotificationMode mode) async {
    switch (mode) {
      case NotificationMode.none:
        break;
      case NotificationMode.vibration:
        await _vibrate();
        break;
      case NotificationMode.sound:
        await _playFullSequencePreview();
        break;
    }
  }

  Future<void> _playFullSequencePreview() async {
    await _playBellSound();
    await Future.delayed(const Duration(milliseconds: 800));
    await _playBellSound();
    await Future.delayed(const Duration(milliseconds: 800));
    await _playBellSound();
    await Future.delayed(const Duration(milliseconds: 800));
    await _playGoSound();
  }

  Future<void> _playBellSound() => _playOnNextPlayer(_bellAsset);

  Future<void> _playGoSound() => _playOnNextPlayer(_goAsset);

  // Alterne entre les lecteurs du pool à chaque appel (round-robin) :
  // deux déclenchements rapprochés (bip -> bip, ou bip -> son de fin)
  // n'utilisent donc jamais le même AudioPlayer, contournant le risque
  // de non-relecture d'une même source sur un lecteur qui vient tout
  // juste de la jouer.
  Future<void> _playOnNextPlayer(String asset) {
    final player = _players[_nextPlayerIndex];
    _nextPlayerIndex = (_nextPlayerIndex + 1) % _players.length;
    return player.play(AssetSource(asset));
  }

  // Utilise le package `vibration` (Vibrator Android natif) plutôt que
  // HapticFeedback.vibrate() : ce dernier respecte le réglage système
  // "Retour haptique tactile" (celui du clavier/boutons) et non le
  // moteur de vibration général — sur de nombreux appareils où ce
  // réglage est désactivé, HapticFeedback ne produit alors aucune
  // vibration perceptible, silencieusement.
  Future<void> _vibrate() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      await Vibration.vibrate(duration: _vibrationDurationMs);
    }
  }

  void dispose() {
    for (final player in _players) {
      player.dispose();
    }
  }
}
