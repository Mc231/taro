import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:taro/data/backup/backup_migrator.dart';
import 'package:taro/data/backup/journal_backup_store.dart';
import 'package:taro_core/taro_core.dart';

/// Runs [task] off the UI isolate and returns its result. Production uses
/// `Isolate.run`; tests may run inline.
typedef BackupTaskRunner = Future<R> Function<R>(FutureOr<R> Function() task);

/// An encoded backup file.
final class EncodedBackup {
  /// Creates an encoded backup.
  const EncodedBackup({required this.backup, required this.bytes});

  /// The typed backup, including its `checksum`.
  final BackupV1 backup;

  /// The UTF-8 JSON file content.
  final Uint8List bytes;
}

/// Encodes and decodes `taro.backup` files (01 §7.11, 02 §12, RC17, RC70).
///
/// **Encode:** the exportable journal (settings; `complete`, `refused` and
/// `classic` readings; daily cards) inside the `data` wrapper, with
/// `checksum` = lowercase hex SHA-256 of the RFC 8785 (JCS) canonical JSON
/// of `data` (`BackupChecksum`). Only fields of `backup_schema_v1.json` are
/// written: never credits, entitlements, install ID, install secret,
/// tokens, the outbox, consent or config (06 §2.5).
///
/// **Decode** (the `ImportBackup` pipeline up to the preview): size ≤ 20 MB
/// → JSON → `format` → `schemaVersion` ≤ current → [BackupMigrator] →
/// `BackupValidator` (schema, forbidden keys, ≤ 50,000 entries, card IDs in
/// the deck, checksum). Every failure is a `BackupInvalidFailure`.
///
/// JSON, hashing and validation run in a background isolate (`runner`,
/// `Isolate.run` by default).
final class BackupCodec {
  /// Creates a codec.
  BackupCodec({
    this.migrator = const BackupMigrator(),
    BackupTaskRunner runner = Isolate.run,
  }) : _run = runner;

  /// The migration chain.
  final BackupMigrator migrator;

  final BackupTaskRunner _run;

  /// Encodes [data]; readings that are never exported are dropped.
  Future<EncodedBackup> encode(
    BackupData data, {
    required DateTime exportedAt,
    required String appVersion,
  }) => _run(
    () => encodeSync(data, exportedAt: exportedAt, appVersion: appVersion),
  );

  /// Reads the exportable journal from [store] and encodes it.
  Future<Result<EncodedBackup>> encodeJournal(
    JournalBackupStore store, {
    required DateTime exportedAt,
    required String appVersion,
  }) async {
    final data = await store.exportData();
    return data.then(
      (d) async => Result.ok(
        await encode(d, exportedAt: exportedAt, appVersion: appVersion),
      ),
    );
  }

  /// Decodes and validates file [bytes]. With a [deck], every card ID must
  /// be in it. [reduceMotion] is the device-only setting to keep on the
  /// imported settings.
  Future<Result<BackupV1>> decode(
    List<int> bytes, {
    Deck? deck,
    bool? reduceMotion,
  }) async {
    // Checked before copying the bytes to the isolate.
    if (bytes.length > BackupSchemaV1.maxFileBytes) {
      return const Result.err(
        Failure.backupInvalid(reason: BackupInvalidReason.tooLarge),
      );
    }
    final migrator = this.migrator;
    return _run(
      () => decodeSync(
        bytes,
        migrator: migrator,
        deck: deck,
        reduceMotion: reduceMotion,
      ),
    );
  }

  /// The synchronous body of [encode].
  static EncodedBackup encodeSync(
    BackupData data, {
    required DateTime exportedAt,
    required String appVersion,
  }) {
    final exportable = BackupData.forExport(
      settings: data.settings,
      readings: data.readings,
      dailyCards: data.dailyCards,
    );
    final backup = BackupV1(
      exportedAt: exportedAt.toUtc(),
      appVersion: appVersion,
      data: exportable,
      checksum: BackupChecksum.of(exportable),
    );
    return EncodedBackup(
      backup: backup,
      bytes: Uint8List.fromList(utf8.encode(jsonEncode(backup.toJson()))),
    );
  }

  /// The synchronous body of [decode].
  static Result<BackupV1> decodeSync(
    List<int> bytes, {
    BackupMigrator migrator = const BackupMigrator(),
    Deck? deck,
    bool? reduceMotion,
  }) {
    if (bytes.length > BackupSchemaV1.maxFileBytes) {
      return _fail(BackupInvalidReason.tooLarge);
    }
    final Object? json;
    try {
      var text = utf8.decode(bytes);
      if (text.startsWith('﻿')) text = text.substring(1);
      json = jsonDecode(text);
    } on FormatException {
      return _fail(BackupInvalidReason.notJson);
    }
    if (json is! Map<String, Object?> || json['format'] != BackupV1.format) {
      return _fail(BackupInvalidReason.wrongFormat);
    }
    final validator = BackupValidator(
      deck: deck,
      currentSchemaVersion: migrator.currentVersion,
    );
    return switch (migrator.migrate(json)) {
      Err(:final failure) => Result.err(failure),
      Ok(:final value) => validator.validateJson(
        value,
        reduceMotion: reduceMotion,
      ),
    };
  }

  static Result<BackupV1> _fail(BackupInvalidReason reason) =>
      Result.err(Failure.backupInvalid(reason: reason));
}
