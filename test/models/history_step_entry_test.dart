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
    expect(decoded.iconName, isNull);
    expect(decoded.hasTabataMetadata, isFalse);
  });

  test('conserve icône, tour et cycle Tabata dans le snapshot JSON', () {
    final entry = HistoryStepEntry(
      groupId: 'tabata',
      groupName: 'Tabata',
      itemType: ItemType.exercise,
      itemName: 'Burpees',
      comment: 'Explosif',
      iconName: 'local_fire_department',
      actualDuration: const Duration(seconds: 20),
      completed: false,
      tabataRoundIndex: 2,
      tabataRoundTotal: 3,
      tabataCycleIndex: 4,
      tabataCycleTotal: 5,
    );

    final decoded = HistoryStepEntry.fromJson(entry.toJson());

    expect(decoded.iconName, 'local_fire_department');
    expect(decoded.tabataRoundIndex, 2);
    expect(decoded.tabataRoundTotal, 3);
    expect(decoded.tabataCycleIndex, 4);
    expect(decoded.tabataCycleTotal, 5);
  });

  test('refuse des métadonnées Tabata partielles ou hors bornes', () {
    HistoryStepEntry invalid({int? roundTotal = 2}) => HistoryStepEntry(
      groupId: 'tabata',
      groupName: 'Tabata',
      itemType: ItemType.exercise,
      itemName: 'Burpees',
      comment: null,
      actualDuration: const Duration(seconds: 20),
      completed: true,
      tabataRoundIndex: 2,
      tabataRoundTotal: roundTotal,
      tabataCycleIndex: 1,
      tabataCycleTotal: 1,
    );

    expect(() => invalid(roundTotal: null), throwsFormatException);
    expect(() => invalid(roundTotal: 1), throwsFormatException);
  });
}
