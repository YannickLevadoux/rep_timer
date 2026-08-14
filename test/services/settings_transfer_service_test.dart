import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/models/backup_import_models.dart';
import 'package:rep_timer/models/backup_v2_payload.dart';
import 'package:rep_timer/models/exportable_app_settings.dart';
import 'package:rep_timer/models/notification_mode.dart';
import 'package:rep_timer/services/backup_export_exception.dart';
import 'package:rep_timer/services/backup_export_service.dart';
import 'package:rep_timer/services/backup_import_exception.dart';
import 'package:rep_timer/services/backup_import_service.dart';
import 'package:rep_timer/services/backup_v2_encoder.dart';
import 'package:rep_timer/services/settings_transfer_platform.dart';
import 'package:rep_timer/services/settings_transfer_service.dart';

void main() {
  group('export et partage', () {
    test('orchestre une seule fois un export v2 dans le bon ordre', () async {
      final events = <String>[];
      final payload = _payload();
      final exporter = _FakeBackupExportService(
        payload: payload,
        onBuild: () => events.add('construction'),
      );
      String? writtenContent;
      DateTime? writtenAt;
      String? sharedPath;
      final service = SettingsTransferService(
        backupService: exporter,
        encodeBackup: (value) {
          events.add('encodage');
          expect(value, same(payload));
          return BackupV2Encoder.encode(value);
        },
        writeBackup: (content, {required exportedAt}) async {
          events.add('écriture');
          writtenContent = content;
          writtenAt = exportedAt;
          return '/cache/reptimer_backup.json';
        },
        shareBackup: (path) async {
          events.add('partage');
          sharedPath = path;
        },
      );

      await service.exportAndShare();

      expect(exporter.buildCalls, 1);
      expect(events, ['construction', 'encodage', 'écriture', 'partage']);
      expect(writtenContent, contains('"exportFormatVersion": 3'));
      expect(writtenAt, payload.exportedAt);
      expect(sharedPath, '/cache/reptimer_backup.json');
    });

    for (final failureStage in ['construction', 'encodage', 'écriture']) {
      test('arrête l’export si $failureStage échoue', () async {
        final events = <String>[];
        final error = StateError('private-$failureStage-content');
        final exporter = _FakeBackupExportService(
          payload: _payload(),
          error: failureStage == 'construction' ? error : null,
          onBuild: () => events.add('construction'),
        );
        final service = SettingsTransferService(
          backupService: exporter,
          encodeBackup: (payload) {
            events.add('encodage');
            if (failureStage == 'encodage') throw error;
            return BackupV2Encoder.encode(payload);
          },
          writeBackup: (content, {required exportedAt}) async {
            events.add('écriture');
            if (failureStage == 'écriture') throw error;
            return '/cache/backup.json';
          },
          shareBackup: (_) async => events.add('partage'),
        );

        await expectLater(service.exportAndShare(), throwsA(same(error)));

        expect(events, switch (failureStage) {
          'construction' => ['construction'],
          'encodage' => ['construction', 'encodage'],
          _ => ['construction', 'encodage', 'écriture'],
        });
      });
    }

    test('convertit l’échec du partage sans exposer le contenu', () async {
      const privateContent = 'private-user-backup-content';
      final service = SettingsTransferService(
        backupService: _FakeBackupExportService(payload: _payload()),
        encodeBackup: (_) => privateContent,
        writeBackup: (content, {required exportedAt}) async {
          expect(content, privateContent);
          return '/cache/backup.json';
        },
        shareBackup: (_) async => throw StateError(privateContent),
      );

      await expectLater(
        service.exportAndShare(),
        throwsA(
          isA<BackupExportException>()
              .having(
                (error) => error.kind,
                'kind',
                BackupExportFailureKind.share,
              )
              .having(
                (error) => '${error.toString()} ${error.userMessage}',
                'diagnostic sûr',
                isNot(contains(privateContent)),
              ),
        ),
      );
    });
  });

  group('sélection et import', () {
    test(
      'lit le contenu du fichier avec l’implémentation de production',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'reptimer_transfer_read_',
        );
        addTearDown(() => directory.delete(recursive: true));
        final file = File('${directory.path}/backup.json');
        await file.writeAsString('{"private":"user-content"}');

        expect(
          await SettingsTransferPlatform.readBackup(file.path),
          '{"private":"user-content"}',
        );
      },
    );

    for (final scenario in <({String name, BackupFileSelection? selection})>[
      (name: 'annulation', selection: null),
      (
        name: 'résultat sans chemin',
        selection: const BackupFileSelection(path: null),
      ),
    ]) {
      test('${scenario.name} retourne null sans lecture ni import', () async {
        var readCalls = 0;
        final importer = _FakeBackupImportService();
        final service = SettingsTransferService(
          importService: importer,
          pickBackup: () async => scenario.selection,
          readBackup: (_) async {
            readCalls++;
            return 'inattendu';
          },
        );

        expect(await service.pickAndImport(), isNull);
        expect(readCalls, 0);
        expect(importer.importCalls, 0);
        expect(importer.restoreCalls, 0);
      });
    }

    test('propage une erreur de sélection sans lecture ni import', () async {
      final error = StateError('private-picker-error');
      var readCalls = 0;
      final importer = _FakeBackupImportService();
      final service = SettingsTransferService(
        importService: importer,
        pickBackup: () async => throw error,
        readBackup: (_) async {
          readCalls++;
          return 'inattendu';
        },
      );

      await expectLater(service.pickAndImport(), throwsA(same(error)));
      expect(readCalls, 0);
      expect(importer.importCalls, 0);
      expect(importer.restoreCalls, 0);
    });

    for (final outcome in <BackupImportOutcome>[
      const V1ImportCompleted(3),
      V2RestorePending(plan: _plan(), localDataWarning: true),
    ]) {
      test(
        'transmet exactement le JSON et le résultat ${outcome.runtimeType}',
        () async {
          const path = '/documents/reptimer.json';
          const content = '{"private":"user-content"}';
          String? readPath;
          final importer = _FakeBackupImportService(outcome: outcome);
          final service = SettingsTransferService(
            importService: importer,
            pickBackup: () async => const BackupFileSelection(path: path),
            readBackup: (value) async {
              readPath = value;
              return content;
            },
          );

          final result = await service.pickAndImport();

          expect(readPath, path);
          expect(importer.importedContents, [content]);
          expect(result, same(outcome));
          expect(importer.restoreCalls, 0);
        },
      );
    }

    test('propage une erreur de lecture sans tenter l’import', () async {
      final error = StateError('private-read-error');
      final importer = _FakeBackupImportService();
      final service = SettingsTransferService(
        importService: importer,
        pickBackup: () async =>
            const BackupFileSelection(path: '/documents/backup.json'),
        readBackup: (_) async => throw error,
      );

      await expectLater(service.pickAndImport(), throwsA(same(error)));
      expect(importer.importCalls, 0);
      expect(importer.restoreCalls, 0);
    });

    test(
      'propage une erreur métier de préparation sans restauration',
      () async {
        const error = BackupImportException(
          BackupImportFailureKind.invalidJson,
        );
        final importer = _FakeBackupImportService(importError: error);
        final service = SettingsTransferService(
          importService: importer,
          pickBackup: () async =>
              const BackupFileSelection(path: '/documents/backup.json'),
          readBackup: (_) async => 'private-invalid-content',
        );

        await expectLater(service.pickAndImport(), throwsA(same(error)));
        expect(importer.importCalls, 1);
        expect(importer.restoreCalls, 0);
      },
    );
  });

  group('restauration v2', () {
    test(
      'attend un appel explicite avant de restaurer le plan préparé',
      () async {
        final plan = _plan();
        final outcome = V2RestorePending(plan: plan, localDataWarning: false);
        final importer = _FakeBackupImportService(outcome: outcome);
        final service = SettingsTransferService(
          importService: importer,
          pickBackup: () async =>
              const BackupFileSelection(path: '/documents/backup.json'),
          readBackup: (_) async => '{}',
        );

        expect(await service.pickAndImport(), same(outcome));
        expect(importer.restoreCalls, 0);

        await service.restoreV2(plan);

        expect(importer.restoreCalls, 1);
        expect(importer.restoredPlans.single, same(plan));
      },
    );

    test('propage l’erreur métier de restauration', () async {
      const error = BackupImportException(
        BackupImportFailureKind.restoreFailed,
      );
      final importer = _FakeBackupImportService(restoreError: error);
      final service = SettingsTransferService(importService: importer);
      final plan = _plan();

      await expectLater(service.restoreV2(plan), throwsA(same(error)));

      expect(importer.restoreCalls, 1);
      expect(importer.restoredPlans.single, same(plan));
    });
  });
}

BackupV2Payload _payload() => BackupV2Payload(
  exportedAt: DateTime.parse('2026-08-11T12:34:56.789Z'),
  trainings: const [],
  history: const [],
  preferences: const {
    'themeMode': 'system',
    'prefillExerciseName': true,
    'notificationMode': 'none',
  },
);

BackupV2RestorePlan _plan() => BackupV2RestorePlan(
  exportedAt: DateTime.parse('2026-08-11T12:34:56.789Z'),
  trainings: const [],
  history: const [],
  settings: const ExportableAppSettings(
    themeMode: ThemeMode.system,
    prefillExerciseName: true,
    notificationMode: NotificationMode.none,
  ),
);

class _FakeBackupExportService extends BackupExportService {
  _FakeBackupExportService({required this.payload, this.error, this.onBuild});

  final BackupV2Payload payload;
  final Object? error;
  final void Function()? onBuild;
  int buildCalls = 0;

  @override
  Future<BackupV2Payload> buildPayload() async {
    buildCalls++;
    onBuild?.call();
    if (error case final error?) throw error;
    return payload;
  }
}

class _FakeBackupImportService extends BackupImportService {
  _FakeBackupImportService({this.outcome, this.importError, this.restoreError});

  final BackupImportOutcome? outcome;
  final Object? importError;
  final Object? restoreError;
  final List<String> importedContents = [];
  final List<BackupV2RestorePlan> restoredPlans = [];

  int get importCalls => importedContents.length;
  int get restoreCalls => restoredPlans.length;

  @override
  Future<BackupImportOutcome> importOrPrepare(String content) async {
    importedContents.add(content);
    if (importError case final error?) throw error;
    return outcome!;
  }

  @override
  Future<void> restoreV2(BackupV2RestorePlan plan) async {
    restoredPlans.add(plan);
    if (restoreError case final error?) throw error;
  }
}
