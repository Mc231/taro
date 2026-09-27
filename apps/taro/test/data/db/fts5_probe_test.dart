import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/db/fts5_probe.dart';

void main() {
  group('Fts5Probe', () {
    test('FTS5 MATCH works on the host SQLite (in-memory)', () async {
      final result = await Fts5Probe.runInMemory();
      expect(result.error, isNull, reason: '$result');
      expect(result.fts5Available, isTrue);
      expect(result.matchedRows, 1);
      expect(result.sqliteVersion, startsWith('3.'));
      expect(result.toString(), contains('fts5: true'));
    });

    test('FTS5 MATCH works through driftDatabase (file)', () async {
      final dir = await Directory.systemTemp.createTemp('taro_fts5_');
      addTearDown(() => dir.delete(recursive: true));
      final result = await Fts5Probe.runOnDevice(
        databaseDirectory: () async => dir.path,
        tempDirectoryPath: () async => dir.path,
      );
      expect(result.fts5Available, isTrue, reason: '$result');
    });

    test('reports the error when the SQL fails', () async {
      final executor = NativeDatabase.memory(
        setup: (db) => db.execute(
          // A plain table with the probe name makes CREATE VIRTUAL TABLE
          // IF NOT EXISTS a no-op and the MATCH query fail.
          'CREATE TABLE fts5_probe (question TEXT, note TEXT)',
        ),
      );
      final result = await Fts5Probe.run(executor);
      expect(result.fts5Available, isFalse);
      expect(result.matchedRows, 0);
      expect(result.error, isNotNull);
      expect(result.toString(), contains('error:'));
    });
  });
}
