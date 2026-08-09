import '../models/session_checkpoint.dart';
import 'json_prefs_storage.dart';

/// Contrat du checkpoint courant, injectable dans les cas d'usage de séance.
abstract interface class SessionCheckpointStore {
  Future<void> saveCheckpoint(SessionCheckpoint checkpoint);

  Future<StorageReadResult<SessionCheckpoint>> loadCheckpoint();

  Future<void> clearCheckpoint();
}

/// Sauvegarde locale du checkpoint de la séance actuellement en cours
/// (une seule séance active à la fois dans l'application, donc une seule
/// clé). Même mécanisme JSON/SharedPreferences que le reste de l'app.
class SessionCheckpointStorage implements SessionCheckpointStore {
  static const storageKey = 'session_checkpoint';

  final JsonObjectStorage<SessionCheckpoint> _storage =
      JsonObjectStorage<SessionCheckpoint>(
        storageKey: storageKey,
        fromJson: SessionCheckpoint.fromJson,
        toJson: (c) => c.toJson(),
      );

  @override
  Future<void> saveCheckpoint(SessionCheckpoint checkpoint) =>
      _storage.save(checkpoint);

  @override
  Future<StorageReadResult<SessionCheckpoint>> loadCheckpoint() =>
      _storage.load();

  @override
  Future<void> clearCheckpoint() => _storage.clear();
}
