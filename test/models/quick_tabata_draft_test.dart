import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/quick_tabata_draft.dart';
import 'package:rep_timer/models/training_item.dart';

void main() {
  test('construit la séance temporaire et estime sans la dernière pause', () {
    final draft = QuickTabataDraft(
      name: 'Tabata',
      workDuration: const Duration(seconds: 20),
      pauseDuration: const Duration(seconds: 10),
      rounds: 3,
    );
    final createdAt = DateTime(2026, 8, 5);

    final training = draft.build(createdAt: createdAt);

    expect(training.id, 'quick_${createdAt.microsecondsSinceEpoch}');
    expect(training.name, 'Tabata');
    expect(training.createdAt, createdAt);
    expect(training.groups.single.rounds, 3);
    expect(training.groups.single.items, hasLength(2));
    expect(training.groups.single.items.last.type, ItemType.rest);
    expect(draft.estimatedDuration, const Duration(seconds: 80));
  });
}
