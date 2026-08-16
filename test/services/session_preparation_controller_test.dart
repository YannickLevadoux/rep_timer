import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/services/session_preparation_controller.dart';

void main() {
  late DateTime now;
  late List<int> signals;
  late int completions;
  late int changes;

  SessionPreparationController build(int seconds) =>
      SessionPreparationController(
        seconds: seconds,
        now: () => now,
        onSignal: signals.add,
        onChanged: () => changes++,
        onCompleted: () => completions++,
      );

  setUp(() {
    now = DateTime(2026);
    signals = [];
    completions = 0;
    changes = 0;
  });

  test('traverse chaque seconde et signale 3, 2, 1 puis le départ', () {
    final controller = build(5)..start();

    for (var second = 1; second <= 5; second++) {
      now = now.add(const Duration(seconds: 1));
      controller.tick();
      expect(controller.remainingSeconds, 5 - second);
    }

    expect(signals, [3, 2, 1, 0]);
    expect(completions, 1);
    expect(controller.preparing, isFalse);
  });

  test('une durée courte ne signale que les valeurs traversées', () {
    final controller = build(2)..start();
    now = now.add(const Duration(seconds: 2));
    controller.tick();

    expect(signals, [2, 1, 0]);
    expect(completions, 1);
  });

  test('pause et reprise conservent la fraction de seconde exacte', () {
    final controller = build(3)..start();
    now = now.add(const Duration(milliseconds: 400));
    controller.pause();
    now = now.add(const Duration(seconds: 20));
    controller.tick();

    expect(controller.remainingSeconds, 3);
    expect(controller.elapsed, const Duration(milliseconds: 400));

    controller.resume();
    now = now.add(const Duration(milliseconds: 599));
    controller.tick();
    expect(controller.remainingSeconds, 3);
    now = now.add(const Duration(milliseconds: 1));
    controller.tick();
    expect(controller.remainingSeconds, 2);
    expect(signals, [3, 2]);
  });

  test('passer ne termine et ne signale le départ qu’une fois', () {
    final controller = build(15)..start();
    controller
      ..skip()
      ..skip()
      ..tick();

    expect(signals, [0]);
    expect(completions, 1);
    expect(changes, 1);
  });
}
