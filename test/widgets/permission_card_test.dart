import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/widgets/permission_card.dart';

void main() {
  testWidgets('présente le statut, le chargement, l’action et la sémantique', (
    tester,
  ) async {
    var actionCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: PermissionCard(
            icon: Icons.notifications_active_outlined,
            title: 'Notifications de séance',
            description: 'Description',
            statusLabel: 'Consultation en cours',
            statusLoading: true,
            action: FilledButton(
              onPressed: () => actionCalls++,
              child: const Text('Action'),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.bySemanticsLabel('Notifications de séance, Consultation en cours'),
      findsOneWidget,
    );

    await tester.tap(find.text('Action'));
    expect(actionCalls, 1);
  });
}
