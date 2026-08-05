import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'backup_export_exception.dart';
import 'backup_export_service.dart';
import 'backup_file_writer.dart';
import 'backup_v2_encoder.dart';
import 'training_import_service.dart';

typedef BackupShare = Future<void> Function(String filePath);

/// Orchestre les interactions plateforme de l'import/export depuis Paramètres.
///
/// L'écran ne conserve ainsi que la gestion de son état de chargement et des
/// messages destinés à l'utilisateur.
class SettingsTransferService {
  SettingsTransferService({
    BackupExportService? backupService,
    BackupFileWriter? fileWriter,
    TrainingImportService? importService,
    BackupShare? shareBackup,
  }) : _backupService = backupService ?? BackupExportService(),
       _fileWriter = fileWriter ?? BackupFileWriter(),
       _importService = importService ?? TrainingImportService(),
       _shareBackup = shareBackup ?? _shareWithPlatform;

  final BackupExportService _backupService;
  final BackupFileWriter _fileWriter;
  final TrainingImportService _importService;
  final BackupShare _shareBackup;

  Future<void> exportAndShare() async {
    final payload = await _backupService.buildPayload();
    final content = BackupV2Encoder.encode(payload);
    final filePath = await _fileWriter.write(
      content,
      exportedAt: payload.exportedAt,
    );
    try {
      await _shareBackup(filePath);
    } on Object {
      throw const BackupExportException(BackupExportFailureKind.share);
    }
  }

  static Future<void> _shareWithPlatform(String filePath) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: 'Export des séances RepTimer',
      ),
    );
  }

  /// Sélectionne puis importe un fichier. Retourne `null` lorsque
  /// l'utilisateur annule le sélecteur ou que la plateforme ne fournit pas
  /// de chemin exploitable.
  Future<ImportResult?> pickAndImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) return null;

    final content = await File(path).readAsString();
    return _importService.importFromJsonString(content);
  }
}
