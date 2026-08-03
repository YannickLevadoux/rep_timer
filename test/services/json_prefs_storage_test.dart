import 'package:flutter_test/flutter_test.dart';
import 'package:rep_timer/services/json_prefs_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JsonListStorage', () {
    late JsonListStorage<_Value> storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = JsonListStorage<_Value>(
        storageKey: 'values',
        fromJson: _Value.fromJson,
        toJson: (value) => value.toJson(),
      );
    });

    test('distingue une clé absente', () async {
      expect(await storage.loadList(), isA<StorageNoData<List<_Value>>>());
    });

    test('distingue une chaîne vide', () async {
      SharedPreferences.setMockInitialValues({'values': ''});

      expect(await storage.loadList(), isA<StorageNoData<List<_Value>>>());
    });

    test('lit une liste valide dans son ordre historique', () async {
      SharedPreferences.setMockInitialValues({
        'values': '[{"value":"premier"},{"value":"second"}]',
      });

      final result = await storage.loadList();

      expect(result, isA<StorageReadSuccess<List<_Value>>>());
      expect(
        (result as StorageReadSuccess<List<_Value>>).data.map((e) => e.value),
        ['premier', 'second'],
      );
    });

    test(
      'retourne une erreur typée pour un JSON invalide sans le modifier',
      () async {
        const raw = '[{"private":"payload"}';
        SharedPreferences.setMockInitialValues({'values': raw});

        final result = await storage.loadList();

        expect(result, isA<StorageReadFailure<List<_Value>>>());
        expect(
          (result as StorageReadFailure<List<_Value>>).error.kind,
          StorageReadErrorKind.invalidJson,
        );
        expect(result.error.toString(), isNot(contains('private')));
        expect(
          (await SharedPreferences.getInstance()).getString('values'),
          raw,
        );
      },
    );

    test(
      'retourne une erreur typée si la racine n’est pas une liste',
      () async {
        const raw = '{"value":"a"}';
        SharedPreferences.setMockInitialValues({'values': raw});

        final result = await storage.loadList();

        expect(result, isA<StorageReadFailure<List<_Value>>>());
        expect(
          (result as StorageReadFailure<List<_Value>>).error.kind,
          StorageReadErrorKind.invalidRootType,
        );
        expect(
          (await SharedPreferences.getInstance()).getString('values'),
          raw,
        );
      },
    );

    test(
      'retourne une erreur typée si la préférence n’est pas une chaîne',
      () async {
        SharedPreferences.setMockInitialValues({'values': 42});

        final result = await storage.loadList();

        expect(
          (result as StorageReadFailure<List<_Value>>).error.kind,
          StorageReadErrorKind.storageAccess,
        );
        await expectLater(
          storage.saveList([const _Value('replacement')]),
          throwsA(isA<StorageMutationBlockedException>()),
        );
        expect((await SharedPreferences.getInstance()).get('values'), 42);
      },
    );

    test('récupère chaque entrée valide et conserve son ordre', () async {
      const raw = '[{"value":"un"},{"invalid":true},{"value":"trois"},42]';
      SharedPreferences.setMockInitialValues({'values': raw});

      final result = await storage.loadList();

      expect(result, isA<StorageReadPartial<List<_Value>>>());
      final partial = result as StorageReadPartial<List<_Value>>;
      expect(partial.data.map((e) => e.value), ['un', 'trois']);
      expect(partial.rejectedIndexes, [1, 3]);
      expect((await SharedPreferences.getInstance()).getString('values'), raw);
    });

    test('isole une exception levée par le décodeur métier', () async {
      const raw = '[{"value":"ok"},{"value":7}]';
      SharedPreferences.setMockInitialValues({'values': raw});

      final result = await storage.loadList();

      final partial = result as StorageReadPartial<List<_Value>>;
      expect(partial.data.single.value, 'ok');
      expect(partial.rejectedIndexes, [1]);
      expect((await SharedPreferences.getInstance()).getString('values'), raw);
    });

    test('bloque une écriture après une récupération partielle', () async {
      const raw = '[{"value":"ok"},{"invalid":true}]';
      SharedPreferences.setMockInitialValues({'values': raw});

      await expectLater(
        storage.saveList([const _Value('replacement')]),
        throwsA(
          isA<StorageMutationBlockedException>().having(
            (error) => error.state,
            'state',
            StorageBlockedState.partial,
          ),
        ),
      );
      expect((await SharedPreferences.getInstance()).getString('values'), raw);
    });

    test('bloque une écriture après une lecture impossible', () async {
      const raw = 'not-json-user-data';
      SharedPreferences.setMockInitialValues({'values': raw});

      await expectLater(
        storage.saveList([const _Value('replacement')]),
        throwsA(
          isA<StorageMutationBlockedException>().having(
            (error) => error.state,
            'state',
            StorageBlockedState.unreadable,
          ),
        ),
      );
      expect((await SharedPreferences.getInstance()).getString('values'), raw);
    });
  });

  group('JsonObjectStorage', () {
    late JsonObjectStorage<_Value> storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = JsonObjectStorage<_Value>(
        storageKey: 'value',
        fromJson: _Value.fromJson,
        toJson: (value) => value.toJson(),
      );
    });

    test('lit un objet valide', () async {
      SharedPreferences.setMockInitialValues({'value': '{"value":"ok"}'});

      final result = await storage.load();

      expect((result as StorageReadSuccess<_Value>).data.value, 'ok');
    });

    test('distingue une chaîne vide', () async {
      SharedPreferences.setMockInitialValues({'value': ''});

      expect(await storage.load(), isA<StorageNoData<_Value>>());
    });

    test('rejette un type racine incorrect', () async {
      const raw = '[]';
      SharedPreferences.setMockInitialValues({'value': raw});

      final result = await storage.load();

      expect(
        (result as StorageReadFailure<_Value>).error.kind,
        StorageReadErrorKind.invalidRootType,
      );
      expect((await SharedPreferences.getInstance()).getString('value'), raw);
    });

    test(
      'conserve la cause d’un objet métier invalide sans exposer le JSON',
      () async {
        const raw = '{"private":"secret"}';
        SharedPreferences.setMockInitialValues({'value': raw});

        final result = await storage.load();

        final error = (result as StorageReadFailure<_Value>).error;
        expect(error.kind, StorageReadErrorKind.invalidEntity);
        expect(error.cause, isA<TypeError>());
        expect(error.toString(), isNot(contains('secret')));
        expect((await SharedPreferences.getInstance()).getString('value'), raw);
      },
    );

    test('ne sauvegarde ni n’efface un objet illisible', () async {
      const raw = '{invalid-private-json';
      SharedPreferences.setMockInitialValues({'value': raw});

      await expectLater(
        storage.save(const _Value('replacement')),
        throwsA(isA<StorageMutationBlockedException>()),
      );
      await expectLater(
        storage.clear(),
        throwsA(isA<StorageMutationBlockedException>()),
      );
      expect((await SharedPreferences.getInstance()).getString('value'), raw);
    });
  });
}

final class _Value {
  const _Value(this.value);

  factory _Value.fromJson(Map<String, dynamic> json) {
    return _Value(json['value'] as String);
  }

  final String value;

  Map<String, dynamic> toJson() => {'value': value};
}
