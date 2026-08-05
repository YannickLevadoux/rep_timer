import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'training_export_service.dart';

/// Orchestre les interactions plateforme de l'import/export depuis Paramètres.
///
/// La validation et la persistance du contenu restent déléguées à
/// [TrainingExportService]. L'écran ne conserve ainsi que la gestion de son
/// état de chargement et des messages destinés à l'utilisateur.
class SettingsTransferService {
  SettingsTransferService({TrainingExportService? exportService})
    : _exportService = exportService ?? TrainingExportService();

  final TrainingExportService _exportService;

  Future<void> exportAndShare() async {
    final filePath = await _exportService.exportToFile();
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: 'Export des séances RepTimer',
      ),
    );
  }

  /// Sélectionne puis importe un fichier. Retourne `null` lorsque
  /// l'utilisateur annule le sélecteur ou que la plateforme ne fournit pas
  /// de chemin exploitable.
  Future<ImportResult?> pickAndImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) return null;

    final content = await File(path).readAsString();
    return _exportService.importFromJsonString(content);
  }
}
