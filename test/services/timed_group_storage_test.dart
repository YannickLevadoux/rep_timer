import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/services/json_prefs_storage.dart';
import 'package:rep_timer/services/training_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('la lecture locale rejette un groupe temporisé incomplet', () async {
    final invalid = ExerciseGroup.tabata(id: 'tabata')..items.removeLast();
    final training = Training(
      id: 'training',
      name: 'Séance',
      groups: [invalid],
      createdAt: DateTime(2026),
    );
    SharedPreferences.setMockInitialValues({
      TrainingStorage.storageKey: jsonEncode([training.toJson()]),
    });

    final result = await TrainingStorage().loadTrainings();

    expect(result, isA<StorageReadPartial<List<Training>>>());
    expect((result as StorageReadPartial<List<Training>>).rejectedIndexes, [0]);
  });

  test('la lecture locale accepte un groupe temporisé complet', () async {
    final training = Training(
      id: 'training',
      name: 'Séance',
      groups: [ExerciseGroup.emom(id: 'emom')],
      createdAt: DateTime(2026),
    );
    SharedPreferences.setMockInitialValues({
      TrainingStorage.storageKey: jsonEncode([training.toJson()]),
    });

    final result = await TrainingStorage().loadTrainings();

    expect(result, isA<StorageReadSuccess<List<Training>>>());
  });
}
