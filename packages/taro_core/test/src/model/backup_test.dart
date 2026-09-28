import 'dart:convert';
import 'dart:io';

import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

import 'model_fixtures.dart';

/// The 01 §7.11 example file, with the elided values filled in.
Map<String, Object?> exampleFile() => {
  'format': 'taro.backup',
  'schemaVersion': 1,
  'exportedAt': '2026-09-26T08:15:00Z',
  'appVersion': '1.0.0+1',
  'data': {
    'settings': {
      'theme': 'system',
      'reversalsEnabled': true,
      'hapticsEnabled': true,
      'reminder': {'enabled': true, 'time': '09:00'},
      'localeOverride': null,
    },
    'readings': [completeReading().toBackupJson()],
    'dailyCards': [dailyCard().toBackupJson()],
  },
  'checksum': 'a' * 64,
};

/// Keys of `$defs/<name>/properties` in the frozen schema.
Set<String> schemaKeys(Map<String, Object?> schema, String def) {
  final defs = schema[r'$defs']! as Map<String, Object?>;
  final props = (defs[def]! as Map<String, Object?>)['properties']!;
  return (props as Map<String, Object?>).keys.toSet();
}

void main() {
  group('DailyCard', () {
    test('backup round trip and equality', () {
      final card = dailyCard();
      final json = card.toBackupJson();
      expect(json['drawnAt'], '2026-09-25T07:00:00Z');
      expect(json['note'], 'Hope');
      expect(DailyCard.fromBackupJson(json), card);
      expect(card.favourite, isFalse);
      expect(card.copyWith(favourite: true), isNot(card));
    });

    test('rejects an invalid card ID', () {
      final json = dailyCard().toBackupJson()..['cardId'] = 'major_99';
      expect(() => DailyCard.fromBackupJson(json), throwsFormatException);
    });
  });

  group('BackupV1', () {
    test('parses the 01 §7.11 example', () {
      final backup = BackupV1.fromJson(exampleFile(), reduceMotion: true);
      expect(backup.exportedAt, DateTime.utc(2026, 9, 26, 8, 15));
      expect(backup.appVersion, '1.0.0+1');
      expect(backup.checksum, 'a' * 64);
      expect(backup.data.settings.reminder.enabled, isTrue);
      expect(backup.data.settings.reduceMotion, isTrue);
      expect(backup.data.readings.single, completeReading());
      expect(backup.data.dailyCards.single, dailyCard());
      expect(backup.data.entryCount, 2);
    });

    test('round trips to identical JSON', () {
      final file = exampleFile();
      expect(BackupV1.fromJson(file).toJson(), file);
      expect(
        jsonDecode(jsonEncode(BackupV1.fromJson(file).toJson())),
        file,
      );
    });

    test('rejects a wrong format or schema version', () {
      expect(
        () => BackupV1.fromJson(exampleFile()..['format'] = 'other'),
        throwsFormatException,
      );
      expect(
        () => BackupV1.fromJson(exampleFile()..['schemaVersion'] = 2),
        throwsFormatException,
      );
    });

    test('value equality and copyWith', () {
      final a = BackupV1.fromJson(exampleFile());
      expect(a, BackupV1.fromJson(exampleFile()));
      expect(a.copyWith(checksum: 'b' * 64), isNot(a));
      expect(a.data.copyWith(readings: []).entryCount, 1);
    });

    test('file name', () {
      expect(BackupV1.fileName('2026-09-26'), 'taro-backup-2026-09-26.json');
      expect(BackupV1.format, 'taro.backup');
      expect(BackupV1.schemaVersion, 1);
    });

    test('keys match backup_schema_v1.json exactly (RC70)', () {
      final schema =
          jsonDecode(
                File(
                  '../../docs/specs/backup_schema_v1.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final file = BackupV1.fromJson(exampleFile()).toJson();
      expect(
        file.keys.toSet(),
        (schema['properties']! as Map<String, Object?>).keys.toSet(),
      );
      final data = file['data']! as Map<String, Object?>;
      expect(
        (data['settings']! as Map<String, Object?>).keys.toSet(),
        schemaKeys(schema, 'settings'),
      );
      expect(
        ((data['readings']! as List).single as Map<String, Object?>).keys
            .toSet(),
        schemaKeys(schema, 'reading'),
      );
      expect(
        ((data['dailyCards']! as List).single as Map<String, Object?>).keys
            .toSet(),
        schemaKeys(schema, 'dailyCard'),
      );
      expect(content.toJson().keys.toSet(), schemaKeys(schema, 'content'));
    });
  });

  group('BackupData.forExport', () {
    test('drops pending and failed readings (01 §7.11)', () {
      final data = BackupData.forExport(
        settings: const UserSettings(),
        readings: [
          completeReading(id: 'a'),
          completeReading(id: 'b', status: const ReadingStatus.pending()),
          completeReading(
            id: 'c',
            status: const ReadingStatus.failed(Failure.timeout()),
          ),
          completeReading(id: 'd', status: const ReadingStatus.classic()),
        ],
        dailyCards: [dailyCard()],
      );
      expect(data.readings.map((r) => r.id.value), ['a', 'd']);
      expect(data.dailyCards, hasLength(1));
      expect(data.toJson()['readings'], hasLength(2));
    });
  });
}
