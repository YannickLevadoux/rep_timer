import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/widgets/duration_minutes_seconds_picker.dart';

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
}
