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
    return _write(content, fileName(exportedAt));
  }

  Future<String> writeTrainingExport(
    String content, {
    required DateTime exportedAt,
  }) => _write(content, trainingExportFileName(exportedAt));

  Future<String> _write(String content, String fileName) async {
    try {
      final directory = await _directoryProvider();
      final path = '${directory.path}/$fileName';
      await File(path).writeAsString(content);
      return path;
    } on Object {
      throw const BackupExportException(BackupExportFailureKind.fileWrite);
    }
  }

  static String fileName(DateTime exportedAt) {
    return 'reptimer_backup_v3_${_timestamp(exportedAt)}.json';
  }

  static String trainingExportFileName(DateTime exportedAt) {
    return 'reptimer_trainings_v1_${_timestamp(exportedAt)}.json';
  }

  static String _timestamp(DateTime exportedAt) {
    final date = exportedAt.toUtc();
    String digits(int value, int width) => value.toString().padLeft(width, '0');
    final timestamp =
        '${digits(date.year, 4)}${digits(date.month, 2)}'
        '${digits(date.day, 2)}T${digits(date.hour, 2)}'
        '${digits(date.minute, 2)}${digits(date.second, 2)}'
        '${digits(date.millisecond, 3)}Z';
    return timestamp;
  }
}
