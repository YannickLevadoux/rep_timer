/// Échec contrôlé d'une écriture de préférence.
final class AppSettingsWriteException implements Exception {
  const AppSettingsWriteException();

  @override
  String toString() => 'AppSettingsWriteException';
}

/// Échec contrôlé d'une lecture groupée destinée à une sauvegarde complète.
final class AppSettingsReadException implements Exception {
  const AppSettingsReadException();

  @override
  String toString() => 'AppSettingsReadException';
}
