import '../models/backup_import_models.dart';
import '../models/backup_v2_payload.dart';
import 'backup_export_exception.dart';
import 'backup_export_service.dart';
import 'backup_file_writer.dart';
import 'backup_import_service.dart';
import 'backup_v2_encoder.dart';
import 'settings_transfer_platform.dart';

typedef BackupEncoder = String Function(BackupV2Payload payload);

/// Orchestre les interactions plateforme de l'import/export depuis Paramètres.
///
/// L'écran ne conserve ainsi que la gestion de son état de chargement et des
/// messages destinés à l'utilisateur.
class SettingsTransferService {
  SettingsTransferService({
    BackupExportService? backupService,
    BackupFileWriter? fileWriter,
    BackupImportService? importService,
    BackupFilePicker? pickBackup,
    BackupFileReader? readBackup,
    BackupEncoder? encodeBackup,
    BackupWriter? writeBackup,
    BackupShare? shareBackup,
  }) : _backupService = backupService ?? BackupExportService(),
       _importService = importService ?? BackupImportService(),
       _pickBackup = pickBackup ?? SettingsTransferPlatform.pickBackup,
       _readBackup = readBackup ?? SettingsTransferPlatform.readBackup,
       _encodeBackup = encodeBackup ?? BackupV2Encoder.encode,
       _writeBackup = writeBackup ?? (fileWriter ?? BackupFileWriter()).write,
       _shareBackup = shareBackup ?? SettingsTransferPlatform.shareBackup;

  final BackupExportService _backupService;
  final BackupImportService _importService;
  final BackupFilePicker _pickBackup;
  final BackupFileReader _readBackup;
  final BackupEncoder _encodeBackup;
  final BackupWriter _writeBackup;
  final BackupShare _shareBackup;

  Future<void> exportAndShare() async {
    final payload = await _backupService.buildPayload();
    final content = _encodeBackup(payload);
    final filePath = await _writeBackup(
      content,
      exportedAt: payload.exportedAt,
    );
    try {
      await _shareBackup(filePath);
    } on Object {
      throw const BackupExportException(BackupExportFailureKind.share);
    }
  }

  /// Sélectionne puis importe un fichier. Retourne `null` lorsque
  /// l'utilisateur annule le sélecteur ou que la plateforme ne fournit pas
  /// de chemin exploitable.
  Future<BackupImportOutcome?> pickAndImport() async {
    final selection = await _pickBackup();
    final path = selection?.path;
    if (path == null) return null;

    final content = await _readBackup(path);
    return _importService.importOrPrepare(content);
  }

  Future<void> restoreV2(BackupV2RestorePlan plan) =>
      _importService.restoreV2(plan);
}
