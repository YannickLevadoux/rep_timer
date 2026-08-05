import 'dart:convert';

import '../models/backup_v2_payload.dart';

/// Encodage JSON unique des nouvelles sauvegardes RepTimer.
abstract final class BackupV2Encoder {
  static String encode(BackupV2Payload payload) =>
      const JsonEncoder.withIndent('  ').convert(payload.toJson());
}
