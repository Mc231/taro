import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/backup/backup_codec.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contract_support.dart';
import 'support/json_schema.dart';

void main() {
  group('backup_schema_v1.json (RC70)', () {
    test('the app copy is byte-identical to docs/specs', () {
      expect(
        File(kAppSchemaPath).readAsBytesSync(),
        File(kSpecSchemaPath).readAsBytesSync(),
      );
    });

    test('the test checker implements every keyword the schema uses', () {
      expect(BackupJsonSchema.load().unknownKeywords(), isEmpty);
    });

    test('the golden fixture validates against the schema', () {
      final fixture = jsonDecode(File(kAppFixturePath).readAsStringSync());
      expect(BackupJsonSchema.load().validate(fixture), isEmpty);
    });

    test('the schema checker rejects what the schema forbids', () {
      final schema = BackupJsonSchema.load();
      final fixture =
          jsonDecode(File(kAppFixturePath).readAsStringSync())
              as Map<String, Object?>;
      final data = fixture['data']! as Map<String, Object?>;
      final reading =
          (data['readings']! as List<Object?>).first! as Map<String, Object?>;
      final bad = {
        ...fixture,
        'schemaVersion': 2,
        'credits': 5,
        'data': {
          ...data,
          'readings': [
            {
              ...reading,
              'id': 'not-a-uuid',
              'createdAt': 'yesterday',
              'status': 'pending',
              'question': 'q' * 1201,
              'cards': <Object?>[],
              'content': 'text',
              'favourite': 'yes',
            },
          ],
        },
      };
      const pendingStatus =
          r'$.data.readings[0].status = pending is not in '
          '[complete, refused, classic]';
      final problems = schema.validate(bad);
      expect(
        problems,
        containsAll([
          r'$.schemaVersion must be 1',
          r'$.credits is not allowed',
          r'$.data.readings[0].id is not a uuid',
          r'$.data.readings[0].createdAt is not a date-time',
          pendingStatus,
          r'$.data.readings[0].question is longer than 1200',
          r'$.data.readings[0].cards < 1 items',
          r'$.data.readings[0].content matches no anyOf branch',
          r'$.data.readings[0].favourite is not boolean',
        ]),
      );
      expect(
        schema.validate({'format': 'taro.backup'}),
        contains(r'$.data is required'),
      );
      expect(
        schema.validate({
          ...fixture,
          'data': {
            ...data,
            'dailyCards': List.filled(50001, <String, Object?>{}),
          },
        }),
        contains(r'$.data.dailyCards > 50000 items'),
      );
    });
  });

  group('golden fixture test/fixtures/backup_v1_sample.json', () {
    test('is byte-identical to the taro_core fixture', () {
      expect(
        File(kAppFixturePath).readAsBytesSync(),
        File(kCoreFixturePath).readAsBytesSync(),
      );
    });

    test('its known checksum pins the JCS canonicalisation', () {
      final fixture =
          jsonDecode(File(kAppFixturePath).readAsStringSync())
              as Map<String, Object?>;
      expect(fixture['checksum'], kFixtureChecksum);
      expect(BackupChecksum.ofJson(fixture['data']), kFixtureChecksum);
    });

    test('decodes, and re-encodes to the same data and checksum', () async {
      final bytes = File(kAppFixturePath).readAsBytesSync();
      final codec = BackupCodec(runner: _inline);
      final backup = expectOk(await codec.decode(bytes));
      expect(backup.checksum, kFixtureChecksum);

      final encoded = await codec.encode(
        backup.data,
        exportedAt: backup.exportedAt,
        appVersion: backup.appVersion,
      );
      expect(encoded.backup.checksum, kFixtureChecksum);
      final original = jsonDecode(utf8.decode(bytes));
      expect(jsonDecode(utf8.decode(encoded.bytes)), original);
    });
  });
}

Future<R> _inline<R>(FutureOr<R> Function() task) async => task();
