typedef SessionPreparationNow = DateTime Function();

/// État temporel pur précédant une nouvelle séance.
///
/// Le temps écoulé est conservé avec sa précision réelle afin qu'une pause
/// puis une reprise ne perde aucune fraction de seconde. Seul l'affichage est
/// arrondi à la seconde supérieure.
class SessionPreparationController {
  SessionPreparationController({
    required int seconds,
    required this.now,
    required this.onSignal,
    required this.onChanged,
    required this.onCompleted,
  }) : _duration = Duration(seconds: seconds),
       _preparing = seconds > 0;

  final Duration _duration;
  final SessionPreparationNow now;
  final void Function(int secondsRemaining) onSignal;
  final void Function() onChanged;
  final void Function() onCompleted;
  final Set<int> _signalsEmitted = <int>{};

  Duration _elapsed = Duration.zero;
  DateTime? _runningSince;
  bool _preparing;
  bool _paused = false;
  late int _lastReportedSeconds = remainingSeconds;

  bool get preparing => _preparing;
  bool get paused => _paused;
  Duration get elapsed => _elapsed + _currentRun;
  Duration get remaining {
    final value = _duration - elapsed;
    return value.isNegative ? Duration.zero : value;
  }

  int get remainingSeconds {
    final microseconds = remaining.inMicroseconds;
    if (microseconds <= 0) return 0;
    return (microseconds + Duration.microsecondsPerSecond - 1) ~/
        Duration.microsecondsPerSecond;
  }

  void start() {
    if (!_preparing || _runningSince != null) return;
    _runningSince = now();
    _lastReportedSeconds = remainingSeconds;
    _emitThreshold(_lastReportedSeconds);
  }

  void tick() {
    if (!_preparing || _paused || _runningSince == null) return;
    final previous = _lastReportedSeconds;
    final current = remainingSeconds;
    if (current >= previous && current > 0) return;
    _lastReportedSeconds = current;
    _emitCrossedThresholds(previous, current);
    if (current == 0) {
      _complete(signalStart: true);
    } else {
      onChanged();
    }
  }

  void togglePause() => _paused ? resume() : pause();

  void pause() {
    if (!_preparing || _paused) return;
    _captureElapsed();
    _paused = true;
    onChanged();
  }

  void resume() {
    if (!_preparing || !_paused) return;
    _paused = false;
    _runningSince = now();
    onChanged();
  }

  void skip() {
    if (_preparing) _complete(signalStart: true);
  }

  void _emitCrossedThresholds(int previous, int current) {
    for (var value = previous - 1; value >= current; value--) {
      _emitThreshold(value);
    }
  }

  void _emitThreshold(int value) {
    if (value < 0 || value > 3 || !_signalsEmitted.add(value)) return;
    onSignal(value);
  }

  void _complete({required bool signalStart}) {
    _captureElapsed();
    _elapsed = _duration;
    _preparing = false;
    _paused = false;
    if (signalStart) _emitThreshold(0);
    onCompleted();
    onChanged();
  }

  void _captureElapsed() {
    _elapsed += _currentRun;
    _runningSince = null;
  }

  Duration get _currentRun {
    final since = _runningSince;
    if (since == null) return Duration.zero;
    final value = now().difference(since);
    return value.isNegative ? Duration.zero : value;
  }
}
