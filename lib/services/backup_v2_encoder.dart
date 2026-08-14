import '../models/backup_payload.dart';
import 'backup_encoder.dart';

@Deprecated('Utiliser BackupEncoder.')
abstract final class BackupV2Encoder {
  static String encode(BackupPayload payload) => BackupEncoder.encode(payload);
}
