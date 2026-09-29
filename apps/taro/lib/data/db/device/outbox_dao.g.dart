// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox_dao.dart';

// ignore_for_file: type=lint
mixin _$OutboxDaoMixin on DatabaseAccessor<DeviceDatabase> {
  BalanceCache get balanceCache => attachedDatabase.balanceCache;
  RemoteConfigCache get remoteConfigCache => attachedDatabase.remoteConfigCache;
  Entitlements get entitlements => attachedDatabase.entitlements;
  PurchaseOutboxTable get purchaseOutboxTable =>
      attachedDatabase.purchaseOutboxTable;
  ConsentStates get consentStates => attachedDatabase.consentStates;
  SyncState get syncState => attachedDatabase.syncState;
  PendingAcks get pendingAcks => attachedDatabase.pendingAcks;
  OutboxDaoManager get managers => OutboxDaoManager(this);
}

class OutboxDaoManager {
  final _$OutboxDaoMixin _db;
  OutboxDaoManager(this._db);
  $BalanceCacheTableManager get balanceCache =>
      $BalanceCacheTableManager(_db.attachedDatabase, _db.balanceCache);
  $RemoteConfigCacheTableManager get remoteConfigCache =>
      $RemoteConfigCacheTableManager(
        _db.attachedDatabase,
        _db.remoteConfigCache,
      );
  $EntitlementsTableManager get entitlements =>
      $EntitlementsTableManager(_db.attachedDatabase, _db.entitlements);
  $PurchaseOutboxTableTableManager get purchaseOutboxTable =>
      $PurchaseOutboxTableTableManager(
        _db.attachedDatabase,
        _db.purchaseOutboxTable,
      );
  $ConsentStatesTableManager get consentStates =>
      $ConsentStatesTableManager(_db.attachedDatabase, _db.consentStates);
  $SyncStateTableManager get syncState =>
      $SyncStateTableManager(_db.attachedDatabase, _db.syncState);
  $PendingAcksTableManager get pendingAcks =>
      $PendingAcksTableManager(_db.attachedDatabase, _db.pendingAcks);
}
