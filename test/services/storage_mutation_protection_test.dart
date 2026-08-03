import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/session_checkpoint.dart';
import 'package:rep_timer/models/training.dart';
import 'package:rep_timer/models/training_history_entry.dart';
import 'package:rep_timer/services/json_prefs_storage.dart';
import 'package:rep_timer/services/session_checkpoint_storage.dart';
import 'package:rep_timer/services/training_export_service.dart';
import 'package:rep_timer/services/training_history_storage.dart';
import 'package:rep_timer/services/training_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('les anciennes séances valides restent lisibles', () async {
    final training = _training('legacy');
    SharedPreferences.setMockInitialValues({
      'trainings': jsonEncode([training.toJson()]),
    });

    final result = await TrainingStorage().loadTrainings();

    final loaded = (result as StorageReadSuccess<List<Training>>).data.single;
    expect(loaded.id, 'legacy');
    expect(loaded.name, 'Séance legacy');
  });

  test(
    'ajout et suppression refusent une liste de séances partielle',
    () async {
      final raw = jsonEncode([
        _training('valid').toJson(),
        {'broken': true},
      ]);
      SharedPreferences.setMockInitialValues({'trainings': raw});
      final storage = TrainingStorage();

      final result = await storage.loadTrainings();
      expect(result, isA<StorageReadPartial<List<Training>>>());
      expect(
        (result as StorageReadPartial<List<Training>>).data.single.id,
        'valid',
      );
      await expectLater(
        storage.addOrUpdateTraining(_training('new')),
        throwsA(isA<StorageMutationBlockedException>()),
      );
      await expectLater(
        storage.deleteTraining('valid'),
        throwsA(isA<StorageMutationBlockedException>()),
      );
      expect(
        (await SharedPreferences.getInstance()).getString('trainings'),
        raw,
      );
    },
  );

  test('ajout et suppression refusent un historique illisible', () async {
    const raw = 'private-corrupted-history';
    SharedPreferences.setMockInitialValues({'training_history': raw});
    final storage = TrainingHistoryStorage();

    await expectLater(
      storage.addEntry(_historyEntry('new')),
      throwsA(isA<StorageMutationBlockedException>()),
    );
    await expectLater(
      storage.deleteEntry('existing'),
      throwsA(isA<StorageMutationBlockedException>()),
    );
    expect(
      (await SharedPreferences.getInstance()).getString('training_history'),
      raw,
    );
  });

  test('l’import ne remplace pas des séances partiellement lisibles', () async {
    final raw = jsonEncode([_training('valid').toJson(), 12]);
    SharedPreferences.setMockInitialValues({'trainings': raw});
    final service = TrainingExportService();
    const importPayload =
        '{"app":"RepTimer","exportFormatVersion":1,"trainings":[]}';

    await expectLater(
      service.importFromJsonString(importPayload),
      throwsA(isA<StorageMutationBlockedException>()),
    );
    expect((await SharedPreferences.getInstance()).getString('trainings'), raw);
  });

  test(
    'un checkpoint historique valide sans durées détaillées reste lisible',
    () async {
      const raw =
          '{"trainingId":"training","currentIndex":0,"completed":[false],'
          '"globalElapsedSeconds":5,"stepElapsedSeconds":5,"paused":false,'
          '"savedAt":"2026-07-01T10:00:00.000"}';
      SharedPreferences.setMockInitialValues({'session_checkpoint': raw});

      final result = await SessionCheckpointStorage().loadCheckpoint();

      final checkpoint = (result as StorageReadSuccess<SessionCheckpoint>).data;
      expect(checkpoint.trainingId, 'training');
      expect(checkpoint.stepActualDurations, isEmpty);
    },
  );
}

Training _training(String id) {
  return Training(
    id: id,
    name: 'Séance $id',
    groups: const [],
    createdAt: DateTime(2026, 7, 1),
  );
}

TrainingHistoryEntry _historyEntry(String id) {
  return TrainingHistoryEntry(
    id: id,
    trainingId: 'training',
    trainingName: 'Séance',
    date: DateTime(2026, 7, 1),
    totalDuration: const Duration(minutes: 1),
  );
}
