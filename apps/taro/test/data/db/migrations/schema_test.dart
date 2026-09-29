// drift schema tests (02 §6.1, docs/TESTING.md "drift migrations").
//
// Each database has its schema dumped per version in
// db/schema/<name>/drift_schema_v<n>.json and the generated helpers in
// <name>/generated/. The v1 tests prove the code creates exactly the dumped
// schema (tables, indexes, the FTS5 table and its triggers). A version bump
// adds, per database, one `migrateAndValidate` test from every older version
// plus a data-integrity test like the one below.
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/db/journal/journal_database.dart';

import 'device/generated/schema.dart' as device;
import 'journal/generated/schema.dart' as journal;

void main() {
  group('taro_journal.db', () {
    late SchemaVerifier verifier;

    setUpAll(() => verifier = SchemaVerifier(journal.GeneratedHelper()));

    test('v1 created by the code matches the v1 dump', () async {
      final db = JournalDatabase(await verifier.startAt(1));
      addTearDown(db.close);
      await verifier.migrateAndValidate(
        db,
        1,
        options: const ValidationOptions(validateDropped: true),
      );
    });

    test('a fresh database matches the in-code schema', () async {
      final db = JournalDatabase(
        (await verifier.schemaAt(1)).newConnection(),
      );
      addTearDown(db.close);
      await db.validateDatabaseSchema();
    });

    test('data written at v1 reads back through the app database', () async {
      final schema = await verifier.schemaAt(1);
      schema.rawDatabase
        ..execute(
          'INSERT INTO readings (id, spread_id, spread_version, local_date, '
          'status, content_locale, drawn_at, created_at, updated_at, note) '
          "VALUES ('r1', 'single', 1, '2026-09-26', 'classic', 'en', 1, 1, 1, "
          "'quiet moonrise')",
        )
        ..execute(
          'INSERT INTO reading_cards (reading_id, position_id, '
          "position_order, card_id, reversed) VALUES ('r1', 'focus', 0, "
          "'major_18', 1)",
        );
      final db = JournalDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 1);
      final stored = (await db.readingsDao.byId('r1'))!;
      expect(stored.reading.status, 'classic');
      expect(stored.cards.single.cardId, 'major_18');
      expect(
        [for (final hit in await db.readingsDao.search('moon')) hit.ref],
        ['r1'],
      );
    });
  });

  group('taro_device.db', () {
    late SchemaVerifier verifier;

    setUpAll(() => verifier = SchemaVerifier(device.GeneratedHelper()));

    test('v1 created by the code matches the v1 dump', () async {
      final db = DeviceDatabase(await verifier.startAt(1));
      addTearDown(db.close);
      await verifier.migrateAndValidate(
        db,
        1,
        options: const ValidationOptions(validateDropped: true),
      );
    });

    test('a fresh database matches the in-code schema', () async {
      final db = DeviceDatabase((await verifier.schemaAt(1)).newConnection());
      addTearDown(db.close);
      await db.validateDatabaseSchema();
    });

    test('an unknown version is reported', () {
      expect(
        () => verifier.startAt(99),
        throwsA(isA<MissingSchemaException>()),
      );
    });
  });

  test('both databases are at schema version 1', () {
    expect(journal.GeneratedHelper.versions, [1]);
    expect(device.GeneratedHelper.versions, [1]);
  });
}
