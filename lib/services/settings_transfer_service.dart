import '../models/backup_import_models.dart';
import '../models/backup_payload.dart';
import '../models/training.dart';
import 'backup_export_exception.dart';
import 'backup_export_service.dart';
import 'backup_file_writer.dart';
import 'backup_import_service.dart';
import 'backup_encoder.dart';
import 'settings_transfer_platform.dart';
import 'training_export_service.dart';

typedef BackupEncoding = String Function(BackupPayload payload);

/// Orchestre les interactions plateforme de l'import/export depuis Paramètres.
///
/// L'écran ne conserve ainsi que la gestion de son état de chargement et des
/// messages destinés à l'utilisateur.
class SettingsTransferService {
  SettingsTransferService({
    BackupExportService? backupService,
    BackupFileWriter? fileWriter,
    BackupImportService? importService,
    TrainingExportService? trainingExportService,
    BackupFilePicker? pickBackup,
    BackupFileReader? readBackup,
    BackupEncoding? encodeBackup,
    BackupWriter? writeBackup,
    BackupWriter? writeTrainingExport,
    BackupShare? shareBackup,
  }) : _backupService = backupService ?? BackupExportService(),
       _importService = importService ?? BackupImportService(),
       _trainingExportService =
           trainingExportService ?? TrainingExportService(),
       _pickBackup = pickBackup ?? SettingsTransferPlatform.pickBackup,
       _readBackup = readBackup ?? SettingsTransferPlatform.readBackup,
       _encodeBackup = encodeBackup ?? BackupEncoder.encode,
       _writeBackup = writeBackup ?? (fileWriter ?? BackupFileWriter()).write,
       _writeTrainingExport =
           writeTrainingExport ??
           (fileWriter ?? BackupFileWriter()).writeTrainingExport,
       _shareBackup = shareBackup ?? SettingsTransferPlatform.shareBackup;

  final BackupExportService _backupService;
  final BackupImportService _importService;
  final TrainingExportService _trainingExportService;
  final BackupFilePicker _pickBackup;
  final BackupFileReader _readBackup;
  final BackupEncoding _encodeBackup;
  final BackupWriter _writeBackup;
  final BackupWriter _writeTrainingExport;
  final BackupShare _shareBackup;

  Future<TransferShareResult> exportAndShare() async {
    final payload = await _backupService.buildPayload();
    final content = _encodeBackup(payload);
    final filePath = await _writeBackup(
      content,
      exportedAt: payload.exportedAt,
    );
    return _share(filePath);
  }

  Future<List<Training>> loadTrainingsForExport() =>
      _trainingExportService.loadTrainings();

  Future<TransferShareResult> exportTrainingsAndShare(
    List<Training> trainings,
  ) async {
    final payload = _trainingExportService.buildSelection(trainings);
    final content = _trainingExportService.encode(payload);
    final filePath = await _writeTrainingExport(
      content,
      exportedAt: payload.exportedAt,
    );
    return _share(filePath);
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

  Future<int?> pickAndImportTrainings() async {
    final content = await _pickContent();
    if (content == null) return null;
    return _importService.importTrainings(content);
  }

  Future<RestorePending?> pickAndPrepareRestore() async {
    final content = await _pickContent();
    if (content == null) return null;
    return _importService.prepareRestore(content);
  }

  Future<void> restoreBackup(BackupRestorePlan plan) => restoreV2(plan);

  @Deprecated('Utiliser restoreBackup.')
  Future<void> restoreV2(BackupRestorePlan plan) =>
      _importService.restoreBackup(plan);

  Future<String?> _pickContent() async {
    final selection = await _pickBackup();
    final path = selection?.path;
    if (path == null) return null;
    return _readBackup(path);
  }

  Future<TransferShareResult> _share(String filePath) async {
    try {
      return await _shareBackup(filePath);
    } on Object {
      throw const BackupExportException(BackupExportFailureKind.share);
    }
  }
}
