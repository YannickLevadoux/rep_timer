import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'backup_export_exception.dart';

typedef BackupDirectoryProvider = Future<Directory> Function();

/// Écrit un JSON déjà encodé dans le répertoire temporaire de l'application.
class BackupFileWriter {
  BackupFileWriter({BackupDirectoryProvider? directoryProvider})
    : _directoryProvider = directoryProvider ?? getTemporaryDirectory;

  final BackupDirectoryProvider _directoryProvider;

  Future<String> write(String content, {required DateTime exportedAt}) async {
    try {
      final directory = await _directoryProvider();
      final path = '${directory.path}/${fileName(exportedAt)}';
      await File(path).writeAsString(content);
      return path;
    } on Object {
      throw const BackupExportException(BackupExportFailureKind.fileWrite);
    }
  }

  static String fileName(DateTime exportedAt) {
    final date = exportedAt.toUtc();
    String digits(int value, int width) => value.toString().padLeft(width, '0');
    final timestamp =
        '${digits(date.year, 4)}${digits(date.month, 2)}'
        '${digits(date.day, 2)}T${digits(date.hour, 2)}'
        '${digits(date.minute, 2)}${digits(date.second, 2)}'
        '${digits(date.millisecond, 3)}Z';
    return 'reptimer_backup_v3_$timestamp.json';
  }
}
