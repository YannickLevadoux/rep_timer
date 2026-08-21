import 'dart:convert';

import '../models/training.dart';
import '../models/training_export_payload.dart';
import '../validation/business_validation.dart';
import 'backup_export_exception.dart';
import 'json_prefs_storage.dart';
import 'training_storage.dart';

/// Lit et encode les séances destinées au partage additif v1.
class TrainingExportService {
  TrainingExportService({TrainingStorage? storage, DateTime Function()? now})
    : _storage = storage ?? TrainingStorage(),
      _now = now ?? DateTime.now;

  final TrainingStorage _storage;
  final DateTime Function() _now;

  Future<List<Training>> loadTrainings() async {
    final trainings = switch (await _storage.loadTrainings()) {
      StorageNoData<List<Training>>() => <Training>[],
      StorageReadSuccess<List<Training>>(:final data) => data,
      StorageReadPartial<List<Training>>() => throw const BackupExportException(
        BackupExportFailureKind.trainingsPartial,
      ),
      StorageReadFailure<List<Training>>() => throw const BackupExportException(
        BackupExportFailureKind.trainingsUnreadable,
      ),
    };
    _validate(trainings);
    return List.unmodifiable(trainings);
  }

  TrainingExportPayload buildSelection(List<Training> trainings) {
    if (trainings.isEmpty) {
      throw const BackupExportException(BackupExportFailureKind.emptySelection);
    }
    _validate(trainings);
    return TrainingExportPayload(
      exportedAt: _now(),
      trainings: List.unmodifiable(trainings),
    );
  }

  String encode(TrainingExportPayload payload) =>
      const JsonEncoder.withIndent('  ').convert(payload.toJson());

  void _validate(List<Training> trainings) {
    for (var index = 0; index < trainings.length; index++) {
      final issues = BusinessValidation.validateTraining(trainings[index]);
      if (issues.isNotEmpty) {
        throw BackupExportException(
          BackupExportFailureKind.invalidTraining,
          trainingIndex: index,
          issue: issues.first,
        );
      }
    }
  }
}
