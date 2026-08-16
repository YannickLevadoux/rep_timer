import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/widgets/duration_minutes_seconds_picker.dart';
import 'package:rep_timer/widgets/number_wheel_field.dart';

void main() {
  testWidgets('00:00 est refusé explicitement', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DurationMinutesSecondsPicker(
            value: Duration.zero,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('duration-error')), findsOneWidget);
    expect(find.text('La valeur minimale est 1.'), findsOneWidget);
  });

  testWidgets('les roues AMRAP restent entre 01:00 et 60:00', (tester) async {
    var value = const Duration(minutes: 2, seconds: 30);
    late StateSetter updateState;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateState = setState;
              return DurationMinutesSecondsPicker(
                value: value,
                minimum: const Duration(minutes: 1),
                maximum: const Duration(minutes: 60),
                constrainPickerToBounds: true,
                onChanged: (newValue) => updateState(() => value = newValue),
              );
            },
          ),
        ),
      ),
    );

    var wheels = tester
        .widgetList<NumberWheelField>(find.byType(NumberWheelField))
        .toList();
    expect(wheels.first.min, 1);
    expect(wheels.first.max, 60);
    expect(wheels.last.min, 0);
    expect(wheels.last.max, 59);

    wheels.first.onChanged(60);
    await tester.pumpAndSettle();

    expect(value, const Duration(minutes: 60));
    wheels = tester
        .widgetList<NumberWheelField>(find.byType(NumberWheelField))
        .toList();
    expect(wheels.last.min, 0);
    expect(wheels.last.max, 0);

    wheels.first.onChanged(59);
    await tester.pumpAndSettle();

    wheels = tester
        .widgetList<NumberWheelField>(find.byType(NumberWheelField))
        .toList();
    expect(wheels.last.min, 0);
    expect(wheels.last.max, 59);
  });
}
