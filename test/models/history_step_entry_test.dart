import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/history_step_entry.dart';
import 'package:rep_timer/models/training_item.dart';

void main() {
  test('le nombre de répétitions est conservé dans le snapshot JSON', () {
    final entry = HistoryStepEntry(
      groupId: 'group',
      groupName: 'Groupe',
      itemType: ItemType.exercise,
      itemName: 'Squats',
      repetitions: 12,
      comment: null,
      actualDuration: const Duration(seconds: 20),
      completed: true,
    );

    final decoded = HistoryStepEntry.fromJson(entry.toJson());

    expect(decoded.repetitions, 12);
  });

  test('un ancien snapshot sans répétitions reste lisible', () {
    final decoded = HistoryStepEntry.fromJson({
      'groupId': 'group',
      'groupName': 'Groupe',
      'itemType': 'exercise',
      'itemName': 'Gainage',
      'comment': null,
      'actualDurationSeconds': 30,
      'completed': true,
    });

    expect(decoded.repetitions, isNull);
  });
}
