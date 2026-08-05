import 'dart:convert';

import '../models/backup_import_models.dart';
import '../models/notification_mode.dart';
import '../models/training.dart';
import '../models/training_history_entry.dart';
import '../validation/business_validation.dart';
import 'app_settings_storage.dart';
import 'backup_import_exception.dart';
import 'backup_v2_group_validator.dart';
import 'training_import_service.dart';

/// Détection commune des formats puis décodage intégral avant toute mutation.
class BackupImportParser {
  BackupImportParser({TrainingImportService? v1Adapter})
    : _v1Adapter = v1Adapter ?? TrainingImportService();

  final TrainingImportService _v1Adapter;

  BackupImportPlan parse(String content) {
    final Map<String, dynamic> decoded;
    try {
      final value = jsonDecode(content);
      if (value is! Map<String, dynamic>) throw const FormatException();
      decoded = value;
    } on Object {
      throw const BackupImportException(BackupImportFailureKind.invalidJson);
    }

    if (decoded['app'] != 'RepTimer') {
      throw const BackupImportException(
        BackupImportFailureKind.wrongApplication,
      );
    }
    final rawVersion = decoded['exportFormatVersion'];
    final version = rawVersion ?? 1;
    if (version is! int) {
      throw const BackupImportException(
        BackupImportFailureKind.incompleteSchema,
      );
    }

    return switch (version) {
      1 => _v1Adapter.prepareV1(decoded),
      2 => _parseV2(decoded),
      _ => throw BackupImportException(
        BackupImportFailureKind.unsupportedVersion,
        version: version,
      ),
    };
  }

  BackupV2RestorePlan _parseV2(Map<String, dynamic> decoded) {
    final exportedAtRaw = decoded['exportedAt'];
    final data = decoded['data'];
    if (exportedAtRaw is! String || data is! Map<String, dynamic>) {
      throw const BackupImportException(
        BackupImportFailureKind.incompleteSchema,
      );
    }
    final exportedAt = DateTime.tryParse(exportedAtRaw);
    if (exportedAt == null) {
      throw const BackupImportException(
        BackupImportFailureKind.incompatibleData,
      );
    }

    return BackupV2RestorePlan(
      exportedAt: exportedAt,
      trainings: List.unmodifiable(_parseTrainings(data['trainings'])),
      history: List.unmodifiable(_parseHistory(data['history'])),
      settings: _parseSettings(data['preferences']),
    );
  }

  List<Training> _parseTrainings(Object? rawValue) {
    if (rawValue is! List<dynamic>) return _incomplete();
    final trainings = <Training>[];
    for (var index = 0; index < rawValue.length; index++) {
      final raw = rawValue[index];
      if (raw is! Map<String, dynamic>) {
        throw BackupImportException(
          BackupImportFailureKind.invalidTraining,
          entityIndex: index,
        );
      }
      BackupV2GroupValidator.validate(raw, index);

      final Training training;
      try {
        training = Training.fromJson(raw);
      } on Object {
        throw BackupImportException(
          BackupImportFailureKind.invalidTraining,
          entityIndex: index,
        );
      }
      final issues = BusinessValidation.validateTraining(training);
      if (issues.isNotEmpty) {
        throw BackupImportException(
          BackupImportFailureKind.invalidTraining,
          entityIndex: index,
          issue: issues.first,
        );
      }
      trainings.add(training);
    }
    return trainings;
  }

  List<TrainingHistoryEntry> _parseHistory(Object? rawValue) {
    if (rawValue is! List<dynamic>) return _incomplete();
    final history = <TrainingHistoryEntry>[];
    for (var index = 0; index < rawValue.length; index++) {
      try {
        final raw = rawValue[index];
        if (raw is! Map<String, dynamic>) throw const FormatException();
        history.add(TrainingHistoryEntry.fromJson(raw));
      } on Object {
        throw BackupImportException(
          BackupImportFailureKind.invalidHistory,
          entityIndex: index,
        );
      }
    }
    return history;
  }

  ExportableAppSettings _parseSettings(Object? rawValue) {
    if (rawValue is! Map<String, dynamic>) return _incomplete();
    final themeRaw = rawValue['themeMode'];
    final prefill = rawValue['prefillExerciseName'];
    final notificationRaw = rawValue['notificationMode'];
    if (themeRaw is! String || prefill is! bool || notificationRaw is! String) {
      return _incomplete();
    }
    final theme = AppSettingsStorage.deserializeThemeMode(themeRaw);
    NotificationMode? notification;
    for (final mode in NotificationMode.values) {
      if (mode.name == notificationRaw) notification = mode;
    }
    if (theme == null || notification == null) {
      throw const BackupImportException(
        BackupImportFailureKind.incompatibleData,
      );
    }
    return ExportableAppSettings(
      themeMode: theme,
      prefillExerciseName: prefill,
      notificationMode: notification,
    );
  }

  Never _incomplete() => throw const BackupImportException(
    BackupImportFailureKind.incompleteSchema,
  );
}
