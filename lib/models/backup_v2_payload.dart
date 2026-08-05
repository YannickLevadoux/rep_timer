import 'package:flutter/foundation.dart';

const String backupAppIdentifier = 'RepTimer';
const int backupExportFormatVersion = 2;

/// Enveloppe canonique d'une sauvegarde RepTimer v2.
///
/// Le sous-schéma des séances réutilise `Training.toJson()`. Chaque groupe y
/// conserve notamment `type`, `rounds`, `repetitionSequence` dans son ordre,
/// et les `items` avec leurs répétitions individuelles. Les valeurs dormantes
/// restent donc présentes et un groupe variable peut redevenir libre sans
/// perte après restauration.
@immutable
class BackupV2Payload {
  const BackupV2Payload({
    required this.exportedAt,
    required this.trainings,
    required this.history,
    required this.preferences,
  });

  final DateTime exportedAt;
  final List<Map<String, dynamic>> trainings;
  final List<Map<String, dynamic>> history;
  final Map<String, dynamic> preferences;

  Map<String, dynamic> toJson() => {
    'app': backupAppIdentifier,
    'exportFormatVersion': backupExportFormatVersion,
    'exportedAt': exportedAt.toIso8601String(),
    'data': {
      'trainings': trainings,
      'history': history,
      'preferences': preferences,
    },
  };
}
