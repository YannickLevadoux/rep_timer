import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/group_type.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/screens/quick_session_screen.dart';
import 'package:rep_timer/screens/training_session.dart';
import 'package:rep_timer/services/session_controller.dart';
import 'package:rep_timer/services/session_notification_permission_service.dart';
import 'package:rep_timer/widgets/type_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_session_permission_platform.dart';

void main() {
  testWidgets('annuler le dialogue ne modifie pas le commentaire', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final item = TrainingItem(
      type: ItemType.exercise,
      name: 'Squats',
      repetitions: 10,
      comment: 'Commentaire initial',
    );
    final training = Training(
      id: 'training',
      name: 'Séance',
      groups: <ExerciseGroup>[
        ExerciseGroup(id: 'group', name: 'Groupe', items: <TrainingItem>[item]),
      ],
      createdAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(home: TrainingSessionScreen(training: training)),
    );

    await tester.tap(find.byTooltip('Modifier le commentaire'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextField), 'Nouveau commentaire');
    await tester.tap(find.text('Annuler'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(item.comment, 'Commentaire initial');
    expect(
      (await SharedPreferences.getInstance()).getString('trainings'),
      isNull,
    );
  });

  testWidgets('la Session rapide lance une séance temporaire', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QuickSessionScreen(
          permissionService: SessionNotificationPermissionService(
            platform: GrantedSessionPermissionPlatform(),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TypeSelector));
    await tester.pumpAndSettle();
    await tester.tap(find.text(GroupType.tabata.shortLabel).last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Commencer'));
    await tester.tap(find.text('Commencer'));
    await tester.pump(const Duration(milliseconds: 100));

    final session = tester.widget<TrainingSessionScreen>(
      find.byType(TrainingSessionScreen, skipOffstage: false),
    );
    expect(
      session.trainingChangesPersistence,
      TrainingChangesPersistence.memoryOnly,
    );
  });

  test('une séance classique utilise la politique persistante par défaut', () {
    final screen = TrainingSessionScreen(
      training: Training(
        id: 'training',
        name: 'Séance',
        groups: const [],
        createdAt: DateTime(2026),
      ),
    );

    expect(
      screen.trainingChangesPersistence,
      TrainingChangesPersistence.persistent,
    );
  });
}
