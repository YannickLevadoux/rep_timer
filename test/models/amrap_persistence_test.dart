import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/amrap_checkpoint_state.dart';
import 'package:rep_timer/models/amrap_history_data.dart';
import 'package:rep_timer/models/history_step_entry.dart';
import 'package:rep_timer/models/session_checkpoint.dart';
import 'package:rep_timer/models/training_item.dart';

void main() {
  test('le checkpoint AMRAP fait un aller-retour et copie ses tours', () {
    final laps = [const Duration(seconds: 30), const Duration(seconds: 40)];
    final state = AmrapCheckpointState(
      configuredDuration: const Duration(minutes: 2),
      activeElapsed: const Duration(seconds: 75),
      activeRemaining: const Duration(seconds: 45),
      completedLapDurations: laps,
      currentLapDuration: const Duration(seconds: 5),
      buttonDelayRemaining: const Duration(seconds: 1),
      completed: false,
    );
    final checkpoint = _checkpoint(state);
    laps[0] = const Duration(seconds: 99);

    final decoded = SessionCheckpoint.fromJson(checkpoint.toJson());
    expect(decoded.amrapState!.completedLapDurations, [
      const Duration(seconds: 30),
      const Duration(seconds: 40),
    ]);
    expect(decoded.amrapState!.currentLapDuration, const Duration(seconds: 5));
    expect(
      () => decoded.amrapState!.completedLapDurations.add(Duration.zero),
      throwsUnsupportedError,
    );
  });

  test('un ancien checkpoint sans état AMRAP reste lisible', () {
    final json = _checkpoint(null).toJson()
      ..remove('amrapState')
      ..remove('amrapStates');
    expect(SessionCheckpoint.fromJson(json).amrapState, isNull);
  });

  test('conserve toutes les occurrences et leur statut dans le checkpoint', () {
    final running = _state();
    final incomplete = AmrapCheckpointState(
      configuredDuration: const Duration(minutes: 1),
      activeElapsed: const Duration(seconds: 12),
      activeRemaining: const Duration(seconds: 48),
      completedLapDurations: const [],
      currentLapDuration: const Duration(seconds: 12),
      buttonDelayRemaining: Duration.zero,
      completed: false,
      incomplete: true,
    );
    final checkpoint = SessionCheckpoint(
      trainingId: 'training',
      currentIndex: 2,
      completed: const [false, false, false],
      globalElapsed: const Duration(seconds: 22),
      stepElapsed: const Duration(seconds: 10),
      paused: false,
      savedAt: DateTime(2026),
      stepActualDurations: const [
        Duration(seconds: 12),
        Duration.zero,
        Duration(seconds: 10),
      ],
      amrapStates: {0: incomplete, 2: running},
    );

    final decoded = SessionCheckpoint.fromJson(checkpoint.toJson());
    expect(decoded.amrapStates.keys, [0, 2]);
    expect(decoded.amrapStates[0]!.incomplete, isTrue);
    expect(decoded.amrapState!.activeElapsed, const Duration(seconds: 10));
    expect(() => decoded.amrapStates[3] = running, throwsUnsupportedError);
  });

  test('refuse les checkpoints AMRAP incohérents', () {
    expect(
      () => AmrapCheckpointState(
        configuredDuration: const Duration(minutes: 2),
        activeElapsed: const Duration(seconds: 10),
        activeRemaining: const Duration(seconds: 110),
        completedLapDurations: const [Duration(seconds: 5)],
        currentLapDuration: const Duration(seconds: 4),
        buttonDelayRemaining: Duration.zero,
        completed: false,
      ),
      throwsFormatException,
    );
    expect(
      () => _state(laps: List.filled(1000, const Duration(seconds: 1))),
      throwsFormatException,
    );
    expect(() => _state(laps: [Duration.zero]), throwsFormatException);
    expect(
      () => _state(buttonDelay: const Duration(seconds: 3)),
      throwsFormatException,
    );
    expect(
      () => AmrapCheckpointState(
        configuredDuration: const Duration(minutes: 1),
        activeElapsed: Duration.zero,
        activeRemaining: const Duration(minutes: 1),
        completedLapDurations: const [],
        currentLapDuration: Duration.zero,
        buttonDelayRemaining: Duration.zero,
        completed: false,
        incomplete: true,
      ),
      throwsFormatException,
    );
  });

  test('historique à zéro tour, avec partiel et à 999 tours', () {
    final zeroLaps = AmrapHistoryData(
      configuredDuration: const Duration(minutes: 2),
      activeDuration: const Duration(minutes: 2),
      completedLapDurations: const [],
      partialLapDuration: const Duration(minutes: 2),
      completed: true,
    );
    expect(zeroLaps.completedLapDurations, isEmpty);

    final many = AmrapHistoryData(
      configuredDuration: const Duration(seconds: 999),
      activeDuration: const Duration(seconds: 999),
      completedLapDurations: List.filled(999, const Duration(seconds: 1)),
      completed: true,
    );
    expect(
      AmrapHistoryData.fromJson(many.toJson()).completedLapDurations,
      hasLength(999),
    );
  });

  test('l’historique AMRAP et l’index EMOM sont rétrocompatibles', () {
    final amrap = AmrapHistoryData(
      configuredDuration: const Duration(minutes: 2),
      activeDuration: const Duration(seconds: 75),
      completedLapDurations: const [
        Duration(seconds: 30),
        Duration(seconds: 40),
      ],
      partialLapDuration: const Duration(seconds: 5),
      completed: false,
    );
    final entry = _history(amrap: amrap, completed: false, minute: 3);
    final decoded = HistoryStepEntry.fromJson(entry.toJson());
    expect(decoded.amrap!.completedLapDurations, amrap.completedLapDurations);
    expect(decoded.amrap!.partialLapDuration, const Duration(seconds: 5));
    expect(decoded.emomMinuteIndex, 3);

    final legacy = entry.toJson()
      ..remove('amrap')
      ..remove('emomMinuteIndex');
    expect(HistoryStepEntry.fromJson(legacy).amrap, isNull);
    expect(HistoryStepEntry.fromJson(legacy).emomMinuteIndex, isNull);
  });

  test('refuse les historiques AMRAP invalides sans correction', () {
    expect(
      () => AmrapHistoryData(
        configuredDuration: const Duration(minutes: 2),
        activeDuration: const Duration(seconds: 10),
        completedLapDurations: const [Duration(seconds: 8)],
        partialLapDuration: const Duration(seconds: 1),
        completed: false,
      ),
      throwsFormatException,
    );
    expect(
      () => AmrapHistoryData(
        configuredDuration: const Duration(minutes: 1),
        activeDuration: Duration.zero,
        completedLapDurations: const [],
        partialLapDuration: Duration.zero,
        completed: false,
      ),
      throwsFormatException,
    );
    expect(
      () => _history(amrap: _validHistory(), completed: true),
      throwsFormatException,
    );
  });
}

AmrapCheckpointState _state({
  List<Duration> laps = const [Duration(seconds: 10)],
  Duration buttonDelay = Duration.zero,
}) => AmrapCheckpointState(
  configuredDuration: const Duration(seconds: 60),
  activeElapsed: Duration(
    seconds: laps.fold(0, (sum, lap) => sum + lap.inSeconds),
  ),
  activeRemaining: Duration(
    seconds: 60 - laps.fold(0, (sum, lap) => sum + lap.inSeconds),
  ),
  completedLapDurations: laps,
  currentLapDuration: Duration.zero,
  buttonDelayRemaining: buttonDelay,
  completed: false,
);

SessionCheckpoint _checkpoint(AmrapCheckpointState? state) => SessionCheckpoint(
  trainingId: 'training',
  currentIndex: 0,
  completed: const [false],
  globalElapsed: const Duration(seconds: 75),
  stepElapsed: const Duration(seconds: 75),
  paused: false,
  savedAt: DateTime(2026),
  stepActualDurations: const [Duration(seconds: 75)],
  amrapState: state,
);

HistoryStepEntry _history({
  AmrapHistoryData? amrap,
  required bool completed,
  int? minute,
}) => HistoryStepEntry(
  groupId: 'group',
  groupName: 'AMRAP',
  itemType: ItemType.exercise,
  itemName: 'Effort',
  comment: null,
  actualDuration: const Duration(seconds: 75),
  completed: completed,
  emomMinuteIndex: minute,
  amrap: amrap,
);

AmrapHistoryData _validHistory() => AmrapHistoryData(
  configuredDuration: const Duration(minutes: 2),
  activeDuration: const Duration(seconds: 75),
  completedLapDurations: const [Duration(seconds: 75)],
  completed: false,
);
