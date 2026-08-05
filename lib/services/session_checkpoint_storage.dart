import '../models/session_checkpoint.dart';
import 'json_prefs_storage.dart';

/// Sauvegarde locale du checkpoint de la séance actuellement en cours
/// (une seule séance active à la fois dans l'application, donc une seule
/// clé). Même mécanisme JSON/SharedPreferences que le reste de l'app.
class SessionCheckpointStorage {
  static const storageKey = 'session_checkpoint';

  final JsonObjectStorage<SessionCheckpoint> _storage =
      JsonObjectStorage<SessionCheckpoint>(
        storageKey: storageKey,
        fromJson: SessionCheckpoint.fromJson,
        toJson: (c) => c.toJson(),
      );

  Future<void> saveCheckpoint(SessionCheckpoint checkpoint) =>
      _storage.save(checkpoint);

  Future<StorageReadResult<SessionCheckpoint>> loadCheckpoint() =>
      _storage.load();

  Future<void> clearCheckpoint() => _storage.clear();
}
