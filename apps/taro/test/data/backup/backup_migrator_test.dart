import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/backup/backup_codec.dart';
import 'package:taro/data/backup/backup_migrator.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contract_support.dart';
import 'support/json_schema.dart';

/// A synthetic v0 layout, to test the migration pattern: no `data`
/// wrapper, `isFavourite` instead of `favourite`, and a checksum over the
/// JCS of `{settings, readings, dailyCards}` at the root.
final class _V0ToV1 implements BackupMigration {
  const _V0ToV1();

  @override
  int get fromVersion => 0;

  @override
  Result<Map<String, Object?>> migrate(Map<String, Object?> document) {
    final body = {
      'settings': document['settings'],
      'readings': document['readings'],
      'dailyCards': document['dailyCards'],
    };
    if (document['checksum'] != BackupChecksum.ofJson(body)) {
      return const Result.err(
        Failure.backupInvalid(reason: BackupInvalidReason.checksum),
      );
    }
    List<Object?> list(String key) => switch (body[key]) {
      final List<Object?> l => l,
      _ => throw FormatException('"$key" must be an array'),
    };
    Map<String, Object?> renamed(Object? entry) {
      final map = Map<String, Object?>.of(entry! as Map<String, Object?>);
      map['favourite'] = map.remove('isFavourite');
      return map;
    }

    return Result.ok(
      BackupMigrator.reseal({
        'format': document['format'],
        'schemaVersion': 1,
        'exportedAt': document['exportedAt'],
        'appVersion': document['appVersion'],
        'data': {
          'settings': body['settings'],
          'readings': list('readings').map(renamed).toList(),
          'dailyCards': list('dailyCards').map(renamed).toList(),
        },
        'checksum': '',
      }),
    );
  }
}

/// A step that claims to migrate but leaves the version as it was.
final class _Stuck implements BackupMigration {
  const _Stuck();

  @override
  int get fromVersion => 0;

  @override
  Result<Map<String, Object?>> migrate(Map<String, Object?> document) =>
      Result.ok(document);
}

/// The golden fixture rewritten in the synthetic v0 layout.
Map<String, Object?> _v0Fixture() {
  final v1 =
      jsonDecode(File(kAppFixturePath).readAsStringSync())
          as Map<String, Object?>;
  final data = v1['data']! as Map<String, Object?>;
  Map<String, Object?> old(Object? entry) {
    final map = Map<String, Object?>.of(entry! as Map<String, Object?>);
    map['isFavourite'] = map.remove('favourite');
    return map;
  }

  final body = {
    'settings': data['settings'],
    'readings': (data['readings']! as List<Object?>).map(old).toList(),
    'dailyCards': (data['dailyCards']! as List<Object?>).map(old).toList(),
  };
  return {
    'format': 'taro.backup',
    'schemaVersion': 0,
    'exportedAt': v1['exportedAt'],
    'appVersion': v1['appVersion'],
    ...body,
    'checksum': BackupChecksum.ofJson(body),
  };
}

Failure _reason(BackupInvalidReason reason) =>
    Failure.backupInvalid(reason: reason);

void main() {
  const chain = BackupMigrator(steps: [_V0ToV1()]);

  test('production has no steps yet: v1 is the first version', () {
    expect(kBackupMigrations, isEmpty);
    expect(const BackupMigrator().currentVersion, BackupV1.schemaVersion);
  });

  test('a current document is returned unchanged', () {
    final doc = {'schemaVersion': 1, 'x': 1};
    expect(identical(expectOk(chain.migrate(doc)), doc), isTrue);
    expect(expectOk(chain.migrate({'schemaVersion': 1.0})), {
      'schemaVersion': 1.0,
    });
  });

  test('synthetic v0 migrates to the golden v1 file, checksum included', () {
    final migrated = expectOk(chain.migrate(_v0Fixture()));
    final golden = jsonDecode(File(kAppFixturePath).readAsStringSync());
    expect(migrated, golden);
    expect(migrated['checksum'], kFixtureChecksum);
    expect(BackupJsonSchema.load().validate(migrated), isEmpty);
  });

  test('the codec imports a v0 file through the chain', () async {
    final codec = BackupCodec(migrator: chain, runner: _inline);
    final bytes = utf8.encode(jsonEncode(_v0Fixture()));
    final backup = expectOk(await codec.decode(bytes));
    expect(backup.checksum, kFixtureChecksum);
    expect(backup.data.readings, hasLength(3));
    expect(backup.data.dailyCards.first.favourite, isTrue);
  });

  test('without a step for v0 the file is invalid (schema)', () {
    expect(
      expectErr(const BackupMigrator().migrate(_v0Fixture())),
      _reason(BackupInvalidReason.schema),
    );
  });

  test('a v0 checksum mismatch stops the chain', () {
    final tampered = {..._v0Fixture(), 'checksum': '0' * 64};
    expect(
      expectErr(chain.migrate(tampered)),
      _reason(BackupInvalidReason.checksum),
    );
  });

  test('a malformed v0 source is a schema failure', () {
    final body = {'settings': null, 'readings': 'x', 'dailyCards': <Object?>[]};
    final bad = {
      'schemaVersion': 0,
      ...body,
      'checksum': BackupChecksum.ofJson(body),
    };
    expect(
      expectErr(chain.migrate(bad)),
      _reason(BackupInvalidReason.schema),
    );
  });

  test('a step that does not advance the version is a schema failure', () {
    expect(
      expectErr(
        const BackupMigrator(steps: [_Stuck()]).migrate({'schemaVersion': 0}),
      ),
      _reason(BackupInvalidReason.schema),
    );
  });

  test('a newer version is unsupportedVersion', () {
    expect(
      expectErr(chain.migrate({'schemaVersion': 2})),
      _reason(BackupInvalidReason.unsupportedVersion),
    );
  });

  test('a missing or non-integral version is a schema failure', () {
    for (final v in [null, '1', 1.5, double.nan]) {
      expect(
        expectErr(chain.migrate({'schemaVersion': v})),
        _reason(BackupInvalidReason.schema),
        reason: '$v',
      );
    }
  });

  test('reseal sets the v1 checksum over data', () {
    final sealed = BackupMigrator.reseal({
      'data': {'a': 1},
      'checksum': 'x',
      'k': true,
    });
    expect(sealed['checksum'], BackupChecksum.ofJson({'a': 1}));
    expect(sealed['k'], isTrue);
  });
}

Future<R> _inline<R>(FutureOr<R> Function() task) async => task();
