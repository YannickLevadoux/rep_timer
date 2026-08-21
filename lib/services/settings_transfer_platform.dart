import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

typedef BackupFilePicker = Future<BackupFileSelection?> Function();
typedef BackupFileReader = Future<String> Function(String filePath);
typedef BackupWriter =
    Future<String> Function(String content, {required DateTime exportedAt});
typedef BackupShare = Future<TransferShareResult> Function(String filePath);

enum TransferShareResult { success, dismissed, unavailable }

/// Résultat minimal du sélecteur nécessaire à l'orchestration de l'import.
final class BackupFileSelection {
  const BackupFileSelection({required this.path});

  final String? path;
}

/// Implémentations de production des frontières plateforme du transfert.
abstract final class SettingsTransferPlatform {
  static Future<BackupFileSelection?> pickBackup() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null) return null;
    return BackupFileSelection(path: result.files.single.path);
  }

  static Future<String> readBackup(String filePath) =>
      File(filePath).readAsString();

  static Future<TransferShareResult> shareBackup(String filePath) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: 'Export des séances RepTimer',
      ),
    );
    return switch (result.status) {
      ShareResultStatus.success => TransferShareResult.success,
      ShareResultStatus.dismissed => TransferShareResult.dismissed,
      ShareResultStatus.unavailable => TransferShareResult.unavailable,
    };
  }
}
