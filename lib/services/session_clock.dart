typedef SessionNow = DateTime Function();

/// Horloge d'une séance : temps global, temps de l'étape courante,
/// pause/reprise et rattrapage du temps mural passé en arrière-plan.
class SessionClock {
  factory SessionClock({
    Duration initialGlobalElapsed = Duration.zero,
    Duration initialStepElapsed = Duration.zero,
    bool initiallyPaused = false,
    DateTime? restoredAt,
    bool active = true,
    SessionNow? now,
  }) => SessionClock._(
    initialGlobalElapsed: initialGlobalElapsed,
    initialStepElapsed: initialStepElapsed,
    initiallyPaused: initiallyPaused,
    restoredAt: restoredAt,
    active: active,
    now: now ?? DateTime.now,
  );

  SessionClock._({
    required Duration initialGlobalElapsed,
    required Duration initialStepElapsed,
    required bool initiallyPaused,
    required DateTime? restoredAt,
    required this._active,
    required this._now,
  }) : _globalElapsedOffset = initialGlobalElapsed,
       _stepElapsedOffset = initialStepElapsed,
       _paused = initiallyPaused {
    if (!_active || _paused) return;

    if (restoredAt != null) {
      final restoredGap = _now().difference(restoredAt);
      if (restoredGap > Duration.zero) {
        _globalElapsedOffset += restoredGap;
        _stepElapsedOffset += restoredGap;
      }
    }

    _runningSince = _now();
  }

  final SessionNow _now;
  final bool _active;

  Duration _globalElapsedOffset;
  Duration _stepElapsedOffset;
  bool _paused;
  DateTime? _runningSince;
  bool _isAppBackgrounded = false;
  DateTime? _backgroundedAt;

  Duration get globalElapsed => _globalElapsedOffset + _runningElapsed;
  Duration get stepElapsed => _stepElapsedOffset + _runningElapsed;
  bool get paused => _paused;
  bool get isAppBackgrounded => _isAppBackgrounded;

  void handleAppBackgrounded() {
    if (!_active || _isAppBackgrounded) return;

    _isAppBackgrounded = true;
    _backgroundedAt = _paused ? null : _now();
    if (_paused) return;
    _captureRunningElapsed();
  }

  bool handleAppResumed() {
    if (!_active || !_isAppBackgrounded) return false;

    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    _isAppBackgrounded = false;
    if (_paused) return false;

    _addWallClockGap(backgroundedAt);
    _runningSince = _now();
    return true;
  }

  /// Affecte le temps d'arrière-plan à l'étape qui vient de finir et
  /// pose immédiatement un nouvel ancrage pour l'étape suivante.
  void captureBackgroundStepEnd() {
    if (!_active || !_isAppBackgrounded || _paused) return;

    _addWallClockGap(_backgroundedAt);
    _backgroundedAt = _now();
  }

  void setPaused(bool paused) {
    if (!_active || paused == _paused) return;

    if (_isAppBackgrounded) {
      if (paused) {
        _addWallClockGap(_backgroundedAt);
        _backgroundedAt = null;
      } else {
        _backgroundedAt = _now();
      }
    }

    _paused = paused;
    if (_paused) {
      _captureRunningElapsed();
    } else if (!_isAppBackgrounded) {
      _runningSince = _now();
    }
  }

  void resetStep() {
    _captureRunningElapsed();
    _stepElapsedOffset = Duration.zero;
    if (_active && !_paused && !_isAppBackgrounded) _runningSince = _now();
  }

  void stop() {
    if (!_active) return;
    if (_isAppBackgrounded && !_paused) {
      _addWallClockGap(_backgroundedAt);
      _backgroundedAt = null;
    } else {
      _captureRunningElapsed();
    }
  }

  Duration get _runningElapsed {
    final since = _runningSince;
    if (since == null) return Duration.zero;
    final elapsed = _now().difference(since);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  void _captureRunningElapsed() {
    final elapsed = _runningElapsed;
    _globalElapsedOffset += elapsed;
    _stepElapsedOffset += elapsed;
    _runningSince = null;
  }

  void _addWallClockGap(DateTime? from) {
    if (from == null) return;
    final gap = _now().difference(from);
    if (gap > Duration.zero) {
      _globalElapsedOffset += gap;
      _stepElapsedOffset += gap;
    }
  }
}
