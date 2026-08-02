import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/services/session_clock.dart';

void main() {
  test('le temps mural est réparti entre les étapes en arrière-plan', () {
    final time = _FakeTime(DateTime(2026));
    final clock = SessionClock(now: time.now);
    clock.handleAppBackgrounded();
    final initialGlobalElapsed = clock.globalElapsed;

    time.advance(const Duration(seconds: 10));
    clock.captureBackgroundStepEnd();
    expect(
      clock.globalElapsed - initialGlobalElapsed,
      const Duration(seconds: 10),
    );
    expect(
      clock.stepElapsed,
      greaterThanOrEqualTo(const Duration(seconds: 10)),
    );

    clock.resetStep();
    time.advance(const Duration(seconds: 6));
    clock.captureBackgroundStepEnd();
    expect(clock.stepElapsed, const Duration(seconds: 6));
    expect(
      clock.globalElapsed - initialGlobalElapsed,
      const Duration(seconds: 16),
    );
  });

  test('une pause en arrière-plan ne compte pas dans la durée', () {
    final time = _FakeTime(DateTime(2026));
    final clock = SessionClock(now: time.now);
    clock.handleAppBackgrounded();
    final initialStepElapsed = clock.stepElapsed;

    time.advance(const Duration(seconds: 4));
    clock.setPaused(true);
    time.advance(const Duration(seconds: 20));
    clock.setPaused(false);
    time.advance(const Duration(seconds: 3));
    clock.captureBackgroundStepEnd();

    expect(clock.stepElapsed - initialStepElapsed, const Duration(seconds: 7));
  });

  test('la restauration rattrape le temps écoulé si la séance jouait', () {
    final savedAt = DateTime(2026);
    final time = _FakeTime(savedAt)..advance(const Duration(seconds: 5));
    final clock = SessionClock(
      initialGlobalElapsed: const Duration(seconds: 12),
      initialStepElapsed: const Duration(seconds: 3),
      restoredAt: savedAt,
      now: time.now,
    );

    expect(
      clock.globalElapsed,
      greaterThanOrEqualTo(const Duration(seconds: 17)),
    );
    expect(clock.stepElapsed, greaterThanOrEqualTo(const Duration(seconds: 8)));
  });
}

class _FakeTime {
  _FakeTime(this.value);

  DateTime value;

  DateTime now() => value;

  void advance(Duration duration) {
    value = value.add(duration);
  }
}
