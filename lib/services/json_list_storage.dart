import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'storage_read_result.dart';

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
