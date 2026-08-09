import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'storage_read_result.dart';

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
    if (current case StorageReadFailure<T>(:final error)) {
      throw StorageMutationBlockedException(
        StorageBlockedState.unreadable,
        readError: error,
      );
    }
  }
}
