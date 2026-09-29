import 'package:drift/drift.dart';
import 'package:taro/data/db/database_location.dart';
import 'package:taro/data/db/device/cache_dao.dart';
import 'package:taro/data/db/device/entitlements_dao.dart';
import 'package:taro/data/db/device/outbox_dao.dart';
import 'package:taro/data/db/device/pending_acks_dao.dart';
import 'package:taro/data/db/instant_converter.dart';
import 'package:taro_core/taro_core.dart';

part 'device_database.g.dart';

/// `taro_device.db` (02 AR7, §6.1, RC75): device-bound state (caches,
/// entitlements, purchase outbox, consent, sync markers, pending acks).
///
/// Excluded from OS backup and device transfer: on every open the file and
/// its `-wal`/`-shm`/`-journal` siblings go through [BackupExclusion] (iOS
/// `NSURLIsExcludedFromBackupKey`); Android lists them in
/// `data_extraction_rules.xml` and `full_backup_content.xml`. After an OS
/// restore this database is empty.
@DriftDatabase(
  daos: [CacheDao, EntitlementsDao, OutboxDao, PendingAcksDao],
  include: {'device.drift'},
)
class DeviceDatabase extends _$DeviceDatabase {
  /// A database over the executor [e] (`NativeDatabase.memory()` in tests).
  /// [afterOpen] runs once the connection is configured.
  DeviceDatabase(super.e, {Future<void> Function()? afterOpen})
    : _afterOpen = afterOpen;

  /// Opens `taro_device.db` at [location] and excludes its files from OS
  /// backup through [backupExclusion]. A failed exclusion is logged and
  /// does not block the app.
  factory DeviceDatabase.open({
    required BackupExclusion backupExclusion,
    required Logger logger,
    DatabaseLocation location = const DatabaseLocation(),
  }) => DeviceDatabase(
    location.open(name),
    afterOpen: () async {
      final path = await location.pathOf('$name.db');
      final result = await backupExclusion.exclude(
        DatabaseLocation.filesOf(path),
      );
      if (result case Err(:final failure)) {
        logger.warning(
          'taro_device.db backup exclusion failed: ${failure.code}',
        );
      }
    },
  );

  /// The drift name; the file is `taro_device.db`.
  static const name = 'taro_device';

  final Future<void> Function()? _afterOpen;

  /// Bump with a `drift_dev make-migrations` dump and a step test
  /// (docs/TESTING.md "drift migrations").
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (_) async {
      await configureConnection(this);
      await _afterOpen?.call();
    },
  );
}
