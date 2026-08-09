/// Résultat typé d'une lecture JSON.
///
/// L'absence, le succès, la récupération partielle et l'échec sont des états
/// distincts. Les appelants peuvent donc décider explicitement s'ils peuvent
/// afficher les données ou les réécrire, sans interpréter un message d'erreur.
sealed class StorageReadResult<T> {
  const StorageReadResult();
}

final class StorageNoData<T> extends StorageReadResult<T> {
  const StorageNoData();
}

final class StorageReadSuccess<T> extends StorageReadResult<T> {
  const StorageReadSuccess(this.data);

  final T data;
}

final class StorageReadPartial<T> extends StorageReadResult<T> {
  const StorageReadPartial(this.data, {required this.rejectedIndexes});

  final T data;
  final List<int> rejectedIndexes;
}

final class StorageReadFailure<T> extends StorageReadResult<T> {
  const StorageReadFailure(this.error);

  final StorageReadException error;
}

enum StorageReadErrorKind {
  storageAccess,
  invalidJson,
  invalidRootType,
  invalidEntity,
}

/// Erreur de lecture qui conserve la cause technique sans inclure le contenu
/// JSON d'origine dans son affichage.
final class StorageReadException implements Exception {
  const StorageReadException({
    required this.kind,
    required this.cause,
    required this.stackTrace,
  });

  final StorageReadErrorKind kind;
  final Object cause;
  final StackTrace stackTrace;

  @override
  String toString() => 'StorageReadException($kind)';
}

enum StorageBlockedState { partial, unreadable }

/// Levée lorsqu'une écriture risquerait de remplacer des données qui n'ont pas
/// pu être relues intégralement.
final class StorageMutationBlockedException implements Exception {
  const StorageMutationBlockedException(this.state, {this.readError});

  final StorageBlockedState state;
  final StorageReadException? readError;

  @override
  String toString() => 'StorageMutationBlockedException($state)';
}
