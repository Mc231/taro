import 'package:drift/drift.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/db/instant_converter.dart';

part 'outbox_dao.g.dart';

/// How long a `finished` outbox row is kept (02 §6.1).
const kOutboxRetention = Duration(days: 30);

/// The persistent purchase outbox (`purchase_outbox`, 04 §6.2, MO8).
@DriftAccessor(include: {'device.drift'})
class OutboxDao extends DatabaseAccessor<DeviceDatabase> with _$OutboxDaoMixin {
  /// Creates the DAO.
  OutboxDao(super.attachedDatabase);

  /// Inserts [row] unless its `txn_key` exists, and returns the stored row
  /// (an existing row is returned unchanged, keeping its idempotency key).
  Future<PurchaseOutboxRow> insertIfAbsent(PurchaseOutboxTableCompanion row) =>
      transaction(() async {
        await into(purchaseOutboxTable).insert(row, onConflict: DoNothing());
        return (await byTxnKey(row.txnKey.value))!;
      });

  /// The row [txnKey], or `null`.
  Future<PurchaseOutboxRow?> byTxnKey(String txnKey) =>
      _where(txnKey).getSingleOrNull();

  /// Open rows (`awaitingVerification` or `granted`), oldest first.
  Future<List<PurchaseOutboxRow>> open() =>
      (select(purchaseOutboxTable)
            ..where(
              (o) => o.status.isIn(const ['awaitingVerification', 'granted']),
            )
            ..orderBy([
              (o) => OrderingTerm.asc(o.createdAt),
              (o) => OrderingTerm.asc(o.txnKey),
            ]))
          .get();

  /// Every row, oldest first.
  Future<List<PurchaseOutboxRow>> all() => (select(
    purchaseOutboxTable,
  )..orderBy([(o) => OrderingTerm.asc(o.createdAt)])).get();

  /// Sets the status of [txnKey]; returns whether the row exists.
  Future<bool> setStatus(
    String txnKey,
    String status, {
    required DateTime now,
  }) async =>
      await (update(
        purchaseOutboxTable,
      )..where((o) => o.txnKey.equals(txnKey))).write(
        PurchaseOutboxTableCompanion(
          status: Value(status),
          updatedAt: Value(now),
        ),
      ) ==
      1;

  /// Counts a verification attempt of [txnKey] and records [error] (a
  /// failure code); returns whether the row exists.
  Future<bool> recordAttempt(
    String txnKey, {
    required DateTime now,
    String? error,
  }) async =>
      await (update(
        purchaseOutboxTable,
      )..where((o) => o.txnKey.equals(txnKey))).write(
        PurchaseOutboxTableCompanion.custom(
          attempts: purchaseOutboxTable.attempts + const Constant(1),
          lastError: Variable(error),
          updatedAt: Variable(const InstantConverter().toSql(now)),
        ),
      ) ==
      1;

  /// Deletes `finished` rows last changed more than [kOutboxRetention]
  /// before [now]; returns how many.
  Future<int> pruneFinished({required DateTime now}) {
    final cutoff = now.subtract(kOutboxRetention);
    return (delete(purchaseOutboxTable)..where(
          (o) =>
              o.status.equals('finished') &
              o.updatedAt.isSmallerThanValue(
                const InstantConverter().toSql(cutoff),
              ),
        ))
        .go();
  }

  SimpleSelectStatement<PurchaseOutboxTable, PurchaseOutboxRow> _where(
    String txnKey,
  ) => select(purchaseOutboxTable)..where((o) => o.txnKey.equals(txnKey));
}
