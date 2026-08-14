import 'package:flutter/foundation.dart';

const String backupAppIdentifier = 'RepTimer';
const int backupExportFormatVersion = 3;

/// Enveloppe canonique de la version de sauvegarde écrite par l'application.
@immutable
class BackupPayload {
  const BackupPayload({
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
