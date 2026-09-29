import 'package:drift/drift.dart';
import 'package:taro/data/db/device/device_database.dart';

part 'pending_acks_dao.g.dart';

/// Delivery acks waiting for `POST /v1/readings/{id}/ack` (RC51).
@DriftAccessor(include: {'device.drift'})
class PendingAcksDao extends DatabaseAccessor<DeviceDatabase>
    with _$PendingAcksDaoMixin {
  /// Creates the DAO.
  PendingAcksDao(super.attachedDatabase);

  /// Queues the ack of [readingId] unless it is queued already.
  Future<void> enqueue(String readingId, {required DateTime now}) =>
      into(pendingAcks).insert(
        PendingAcksCompanion.insert(readingId: readingId, createdAt: now),
        onConflict: DoNothing(),
      );

  /// Every queued ack, oldest first.
  Future<List<PendingAckRow>> all() =>
      (select(pendingAcks)..orderBy([
            (a) => OrderingTerm.asc(a.createdAt),
            (a) => OrderingTerm.asc(a.readingId),
          ]))
          .get();

  /// Counts an attempt for [readingId]; returns whether it is queued.
  Future<bool> recordAttempt(String readingId) async =>
      await (update(
        pendingAcks,
      )..where((a) => a.readingId.equals(readingId))).write(
        PendingAcksCompanion.custom(
          attempts: pendingAcks.attempts + const Constant(1),
        ),
      ) ==
      1;

  /// Removes [readingId] (ack delivered); returns whether it was queued.
  Future<bool> remove(String readingId) async =>
      await (delete(
        pendingAcks,
      )..where((a) => a.readingId.equals(readingId))).go() ==
      1;
}
