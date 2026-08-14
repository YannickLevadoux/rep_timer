import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/services/amrap_execution_state.dart';

void main() {
  test('enregistre, temporise et ignore les doubles appuis', () {
    final state = AmrapExecutionState(const Duration(minutes: 2));

    expect(state.recordLap(Duration.zero, paused: false), isFalse);
    expect(state.recordLap(const Duration(seconds: 41), paused: false), isTrue);
    expect(state.completedLapDurations, [const Duration(seconds: 41)]);
    expect(
      state.recordLap(const Duration(seconds: 41), paused: false),
      isFalse,
    );
    expect(
      state.recordLap(const Duration(seconds: 42), paused: false),
      isFalse,
    );
    expect(state.buttonDelayRemaining, const Duration(seconds: 1));
    expect(state.recordLap(const Duration(seconds: 43), paused: false), isTrue);
    expect(state.completedLapDurations.last, const Duration(seconds: 2));
  });

  test('annule exactement le dernier tour dans le tour courant', () {
    final state = AmrapExecutionState(const Duration(minutes: 2));
    state.recordLap(const Duration(seconds: 41), paused: false);

    expect(state.undoLastLap(const Duration(seconds: 46)), isTrue);
    expect(state.completedLapDurations, isEmpty);
    expect(state.currentLapDuration, const Duration(seconds: 46));
  });

  test('conserve un partiel à expiration sans le compter comme tour', () {
    final state = AmrapExecutionState(const Duration(seconds: 60));
    state.recordLap(const Duration(seconds: 20), paused: false);
    state.synchronize(const Duration(seconds: 60));
    state.markCompleted(const Duration(seconds: 60));

    final history = state.toHistory(stepCompleted: true);
    expect(history.completedLapDurations, [const Duration(seconds: 20)]);
    expect(history.partialLapDuration, const Duration(seconds: 40));
    expect(history.activeDuration, const Duration(seconds: 60));
    expect(state.canUndoLastLap, isFalse);
  });

  test('restaure exactement le tour et le délai depuis le checkpoint', () {
    final original = AmrapExecutionState(const Duration(minutes: 2));
    original.recordLap(const Duration(seconds: 30), paused: false);
    original.synchronize(const Duration(seconds: 31));

    final restored = AmrapExecutionState.fromCheckpoint(
      original.toCheckpoint(),
    );
    expect(restored.completedLapDurations, [const Duration(seconds: 30)]);
    expect(restored.currentLapDuration, const Duration(seconds: 1));
    expect(restored.buttonDelayRemaining, const Duration(seconds: 1));

    restored.synchronize(const Duration(seconds: 32));
    expect(restored.buttonDelayRemaining, Duration.zero);
    expect(restored.currentLapDuration, const Duration(seconds: 2));
  });

  test('la limite de 999 tours conserve le reste comme partiel', () {
    final state = AmrapExecutionState(const Duration(hours: 1));
    var elapsed = 1;
    for (var lap = 0; lap < 999; lap++) {
      expect(
        state.recordLap(Duration(seconds: elapsed), paused: false),
        isTrue,
      );
      elapsed += 2;
    }

    expect(state.limitReached, isTrue);
    expect(state.recordLap(Duration(seconds: elapsed), paused: false), isFalse);
    state.synchronize(const Duration(hours: 1));
    expect(state.currentLapDuration, isNot(Duration.zero));
    expect(state.completedLapCount, 999);
  });

  test('une tentative quittée exige un redémarrage explicite', () {
    final state = AmrapExecutionState(const Duration(minutes: 1));
    state.markIncomplete(const Duration(seconds: 12));

    expect(state.requiresRestart, isTrue);
    expect(
      state.toHistory(stepCompleted: false).partialLapDuration,
      const Duration(seconds: 12),
    );
    state.restart();
    expect(state.requiresRestart, isFalse);
    expect(state.activeRemaining, const Duration(minutes: 1));
  });

  test('un checkpoint conserve le statut incomplet après navigation', () {
    final original = AmrapExecutionState(const Duration(minutes: 1));
    original.markIncomplete(const Duration(seconds: 12));

    final checkpoint = original.toCheckpoint();
    final restored = AmrapExecutionState.fromCheckpoint(checkpoint);

    expect(checkpoint.incomplete, isTrue);
    expect(restored.requiresRestart, isTrue);
    expect(
      restored.toHistory(stepCompleted: false).partialLapDuration,
      const Duration(seconds: 12),
    );
  });
}
