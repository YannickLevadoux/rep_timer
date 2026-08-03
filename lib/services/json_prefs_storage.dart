import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

StorageMutationBlockedException _blockedBy<T>(StorageReadResult<T> result) {
  return switch (result) {
    StorageReadPartial<T>() => const StorageMutationBlockedException(
      StorageBlockedState.partial,
    ),
    StorageReadFailure<T>(:final error) => StorageMutationBlockedException(
      StorageBlockedState.unreadable,
      readError: error,
    ),
    _ => throw StateError('Une lecture saine ne bloque pas les mutations.'),
  };
}

/// Persistance générique d'une liste d'objets en JSON via SharedPreferences.
class JsonListStorage<T> {
  JsonListStorage({
    required this.storageKey,
    required this.fromJson,
    required this.toJson,
  });

  final String storageKey;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T value) toJson;

  Future<StorageReadResult<List<T>>> loadList() async {
    final String? raw;
    try {
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString(storageKey);
    } on Object catch (error, stackTrace) {
      return StorageReadFailure(
        StorageReadException(
          kind: StorageReadErrorKind.storageAccess,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }

    if (raw == null || raw.isEmpty) return const StorageNoData();

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on Object catch (error, stackTrace) {
      return StorageReadFailure(
        StorageReadException(
          kind: StorageReadErrorKind.invalidJson,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }

    if (decoded is! List<dynamic>) {
      return StorageReadFailure(
        StorageReadException(
          kind: StorageReadErrorKind.invalidRootType,
          cause: const FormatException(
            'La racine JSON attendue est une liste.',
          ),
          stackTrace: StackTrace.current,
        ),
      );
    }

    final items = <T>[];
    final rejectedIndexes = <int>[];
    for (var index = 0; index < decoded.length; index++) {
      try {
        final entry = decoded[index];
        if (entry is! Map<String, dynamic>) {
          throw const FormatException('Une entrée JSON doit être un objet.');
        }
        items.add(fromJson(entry));
      } on Object catch (_) {
        rejectedIndexes.add(index);
      }
    }

    if (rejectedIndexes.isNotEmpty) {
      return StorageReadPartial(
        items,
        rejectedIndexes: List.unmodifiable(rejectedIndexes),
      );
    }

    return StorageReadSuccess(items);
  }

  /// N'écrit que si la valeur actuellement stockée est absente ou entièrement
  /// lisible. Une récupération partielle ou un échec laisse le payload intact.
  Future<void> saveList(List<T> items) async {
    final current = await loadList();
    if (current
        case StorageReadPartial<List<T>>() || StorageReadFailure<List<T>>()) {
      throw _blockedBy(current);
    }

    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map(toJson).toList());
    await prefs.setString(storageKey, encoded);
  }
}

/// Persistance générique d'un objet unique (au plus un par clé) en JSON via
/// SharedPreferences.
class JsonObjectStorage<T> {
  JsonObjectStorage({
    required this.storageKey,
    required this.fromJson,
    required this.toJson,
  });

  final String storageKey;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T value) toJson;

  Future<StorageReadResult<T>> load() async {
    final String? raw;
    try {
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString(storageKey);
    } on Object catch (error, stackTrace) {
      return StorageReadFailure(
        StorageReadException(
          kind: StorageReadErrorKind.storageAccess,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }

    if (raw == null || raw.isEmpty) return const StorageNoData();

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on Object catch (error, stackTrace) {
      return StorageReadFailure(
        StorageReadException(
          kind: StorageReadErrorKind.invalidJson,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return StorageReadFailure(
        StorageReadException(
          kind: StorageReadErrorKind.invalidRootType,
          cause: const FormatException('La racine JSON attendue est un objet.'),
          stackTrace: StackTrace.current,
        ),
      );
    }

    try {
      return StorageReadSuccess(fromJson(decoded));
    } on Object catch (error, stackTrace) {
      return StorageReadFailure(
        StorageReadException(
          kind: StorageReadErrorKind.invalidEntity,
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<void> save(T value) async {
    await _ensureMutationIsSafe();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(toJson(value)));
  }

  Future<void> clear() async {
    await _ensureMutationIsSafe();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  Future<void> _ensureMutationIsSafe() async {
    final current = await load();
    if (current case StorageReadFailure<T>()) {
      throw _blockedBy(current);
    }
  }
}
