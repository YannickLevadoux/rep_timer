import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

import '../models/notification_sound.dart';

/// Lecture audio/vibration des notifications de fin d'exercice/pause.
/// Ne connaît aucune logique temporelle (quand déclencher, quand
/// annuler) ni aucun mode : c'est entièrement la responsabilité de
/// [SessionController] (pour les déclenchements réels) et de
/// `SettingsScreen` (pour les aperçus), qui appellent cette classe au
/// bon moment avec le [NotificationSound] voulu. Ce service sait
/// seulement "comment" jouer un son ou vibrer, jamais "quand" ni
/// "quel thème par défaut".
class StepEndNotificationService {
  static const _vibrationDurationMs = 300;

  // Lecteur dédié à la séquence "3-2-1-GO" pendant une séance. Un seul
  // fichier composite par déclenchement ne nécessite plus le pool de
  // lecteurs alternés utilisé par l'ancienne approche multi-fichiers.
  final AudioPlayer _countdownPlayer;

  // Lecteur séparé pour les aperçus (écran Paramètres) : les isoler du
  // lecteur de séance évite toute interférence entre les deux, et rend
  // chacun plus simple à raisonner indépendamment.
  final AudioPlayer _previewPlayer;

  bool _disposed = false;

  StepEndNotificationService({
    AudioPlayer? countdownPlayer,
    AudioPlayer? previewPlayer,
  }) : _countdownPlayer = countdownPlayer ?? AudioPlayer(),
       _previewPlayer = previewPlayer ?? AudioPlayer();

  /// Précharge la source audio de [sound] à l'avance (typiquement une
  /// fois au démarrage d'une séance), pour réduire la latence de la
  /// toute première lecture réelle. Best-effort : une erreur ici ne
  /// doit jamais empêcher la lecture ultérieure via [playCountdown],
  /// qui rechargera la source si besoin.
  Future<void> preload(NotificationSound sound) async {
    if (_disposed) return;
    try {
      await _countdownPlayer.setSource(AssetSource(sound.sequenceAsset));
    } catch (_) {
      // Ignoré : la lecture réelle rechargera la source elle-même.
    }
  }

  /// Joue la séquence composite de [sound] (bips + GO) depuis le début.
  /// Appelé une seule fois par [SessionController] lorsque le point de
  /// déclenchement (T - [NotificationSound.goOffset]) est atteint.
  Future<void> playCountdown(NotificationSound sound) async {
    if (_disposed) return;
    try {
      await _countdownPlayer.stop();
      await _countdownPlayer.play(AssetSource(sound.sequenceAsset));
    } catch (_) {
      // Lecture best-effort : une erreur de lecture audio ne doit
      // jamais faire planter la séance en cours.
    }
  }

  /// Arrête immédiatement la séquence en cours (si elle joue), sans
  /// effet si rien n'est en train de jouer.
  Future<void> stopCountdown() async {
    if (_disposed) return;
    try {
      await _countdownPlayer.stop();
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
      await _previewPlayer.stop();
      await _previewPlayer.play(AssetSource(sound.sequenceAsset));
    } catch (_) {}
  }

  /// Vibration ponctuelle. Utilise le package `vibration` (Vibrator
  /// Android natif) plutôt que HapticFeedback.vibrate() : ce dernier
  /// respecte le réglage système "Retour haptique tactile" (celui du
  /// clavier/boutons) et non le moteur de vibration général — sur de
  /// nombreux appareils où ce réglage est désactivé, HapticFeedback ne
  /// produit alors aucune vibration perceptible, silencieusement.
  Future<void> vibrate() async {
    if (_disposed) return;
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: _vibrationDurationMs);
      }
    } catch (_) {}
  }

  void dispose() {
    _disposed = true;
    unawaited(_countdownPlayer.dispose());
    unawaited(_previewPlayer.dispose());
  }
}
