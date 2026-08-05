import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/exercise_group.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_item.dart';
import 'package:rep_timer/services/training_export_service.dart';
import 'package:rep_timer/services/training_storage.dart';
import 'package:rep_timer/services/json_prefs_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('un import invalide est totalement refusé sans mutation', () async {
    final local = _training(id: 'local', name: 'Locale');
    final originalStorage = jsonEncode([local.toJson()]);
    SharedPreferences.setMockInitialValues({'trainings': originalStorage});

    final valid = _training(id: 'one', name: 'Valide').toJson();
    final invalid = _training(id: 'two', name: 'Invalide').toJson();
    final group = (invalid['groups'] as List).single as Map<String, dynamic>;
    group['rounds'] = 1000;

    await expectLater(
      TrainingExportService().importFromJsonString(
        jsonEncode(_payload([valid, invalid])),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          allOf(contains('Séance 2'), contains('nombre de tours')),
        ),
      ),
    );

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('trainings'), originalStorage);
  });

  test('un import valide nettoie noms et commentaires', () async {
    SharedPreferences.setMockInitialValues({});
    final imported = _training(id: 'one', name: '  Séance importée  ');
    imported.groups.single.name = '  Groupe  ';
    imported.groups.single.items.single
      ..name = '  Exercice  '
      ..comment = '  ligne 1\r\nligne 2  ';

    final result = await TrainingExportService().importFromJsonString(
      jsonEncode(_payload([imported.toJson()])),
    );

    expect(result.importedCount, 1);
    final read = await TrainingStorage().loadTrainings();
    final saved = (read as StorageReadSuccess<List<Training>>).data.single;
    expect(saved.name, 'Séance importée');
    expect(saved.groups.single.name, 'Groupe');
    expect(saved.groups.single.items.single.name, 'Exercice');
    expect(saved.groups.single.items.single.comment, 'ligne 1\nligne 2');
  });
}

Map<String, Object> _payload(List<Map<String, dynamic>> trainings) => {
  'app': 'RepTimer',
  'exportFormatVersion': 1,
  'trainings': trainings,
};

Training _training({required String id, required String name}) => Training(
  id: id,
  name: name,
  createdAt: DateTime(2026),
  groups: [
    ExerciseGroup(
      id: 'group-$id',
      name: 'Groupe',
      items: [
        TrainingItem(
          type: ItemType.exercise,
          name: 'Exercice',
          repetitions: 10,
        ),
      ],
    ),
  ],
);
