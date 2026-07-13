import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rep_timer/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MyApp se construit correctement', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    // Première frame
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Mes entraînements'), findsOneWidget);
  });
}