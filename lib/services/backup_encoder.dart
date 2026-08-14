import 'dart:convert';

import '../models/backup_payload.dart';

abstract final class BackupEncoder {
  static String encode(BackupPayload payload) =>
      const JsonEncoder.withIndent('  ').convert(payload.toJson());
}
