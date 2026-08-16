import 'dart:async';

import '../models/notification_mode.dart';
import '../models/notification_sound.dart';
import 'step_end_notification_service.dart';

/// Déduplique et diffère les signaux de préparation jusqu'au chargement du
/// mode de notification de la séance.
class PreSessionSignalCoordinator {
  PreSessionSignalCoordinator({
    required this.modeProvider,
    required this.notifier,
    required this.sound,
  });

  final NotificationMode Function() modeProvider;
  final StepEndNotifier notifier;
  final NotificationSound sound;
  final List<int> _pending = <int>[];
  final Set<int> _handled = <int>{};
  bool _ready = false;

  void emit(int secondsRemaining) {
    if (!_handled.add(secondsRemaining)) return;
    if (!_ready) {
      _pending.add(secondsRemaining);
      return;
    }
    _dispatch(secondsRemaining);
  }

  void markModeReady() {
    if (_ready) return;
    _ready = true;
    for (final value in _pending) {
      _dispatch(value);
    }
    _pending.clear();
  }

  void discardPending() {
    _ready = true;
    _pending.clear();
  }

  void stop() {
    _pending.clear();
    unawaited(notifier.stopCountdown());
  }

  void _dispatch(int secondsRemaining) {
    switch (modeProvider()) {
      case NotificationMode.sound:
        final currentNotifier = notifier;
        if (currentNotifier is PreSessionSoundNotifier) {
          unawaited(
            (currentNotifier as PreSessionSoundNotifier).playPreparationSignal(
              sound,
              secondsRemaining,
            ),
          );
        } else {
          unawaited(currentNotifier.playCountdown(sound));
        }
      case NotificationMode.vibration:
        unawaited(notifier.vibrate());
      case NotificationMode.none:
        break;
    }
  }
}
