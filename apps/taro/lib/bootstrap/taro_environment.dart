import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:taro/bootstrap/build_defines.dart';
import 'package:taro/bootstrap/error_handlers.dart' as handlers;
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/db/journal/journal_database.dart';
import 'package:taro/data/secure/flutter_secure_store.dart';
import 'package:taro/di/app_graph.dart';
import 'package:taro/di/overrides_dev.dart';
import 'package:taro/di/overrides_prod.dart';
import 'package:taro/services/backup/platform_backup_exclusion.dart';
import 'package:taro/services/device/package_info_app_info.dart';
import 'package:taro/services/logging/logging_logger.dart';
import 'package:taro_core/taro_core.dart';

export 'package:taro/di/app_graph.dart' show TaroDatabases;

/// Everything bootstrap touches on the platform (02 §9.1, RC76), so that
/// `bootstrap(TaroEnvironment)` runs in tests with a fake environment.
abstract interface class TaroEnvironment {
  /// The flavor configuration.
  FlavorConfig get flavor;

  /// `Firebase.initializeApp` (a failure leaves Firebase off).
  Future<void> initFirebase();

  /// Opens `taro_journal.db` and `taro_device.db` (RC75).
  Future<TaroDatabases> openDatabases();

  /// The secure store (install ID and secret, 02 §6.2).
  SecureStore get secureStore;

  /// The provider overrides of the flavor, with the caches loaded.
  Future<List<Override>> buildOverrides(FlavorConfig flavor, TaroDatabases dbs);

  /// `FlutterError.onError` and `PlatformDispatcher.onError` → [crash].
  void installErrorHandlers(CrashReporter crash);

  /// Mounts [app].
  void runApp(widgets.Widget app);
}

/// The SDK entry points of [ProductionEnvironment] (fakes in tests).
@immutable
final class PlatformHooks {
  /// The production entry points.
  const PlatformHooks({
    this.initializeFirebase = _initializeFirebase,
    this.openDatabases = _openDatabases,
    this.loadAppInfo = _loadAppInfo,
    this.runApp = widgets.runApp,
    this.platform = _platform,
    this.deviceLocales = _deviceLocales,
    this.sdks = const GraphSdks(),
    this.debugAttestationToken = BuildDefines.debugAttestationToken,
  });

  /// `Firebase.initializeApp` with the flavor's options (`null`: the
  /// native config file).
  final Future<void> Function(FirebaseOptions? options) initializeFirebase;

  /// Opens both databases.
  final Future<TaroDatabases> Function() openDatabases;

  /// Loads the app / device info.
  final Future<AppInfo> Function() loadAppInfo;

  /// `runApp`.
  final void Function(widgets.Widget app) runApp;

  /// The running platform.
  final TargetPlatform Function() platform;

  /// The device locales.
  final List<Locale> Function() deviceLocales;

  /// The SDK singletons of the graph.
  final GraphSdks sdks;

  /// The dev/staging debug attestation token.
  final String debugAttestationToken;

  static Future<void> _initializeFirebase(FirebaseOptions? options) =>
      Firebase.initializeApp(options: options);
  static Future<AppInfo> _loadAppInfo() => PackageInfoAppInfo.load();
  static TargetPlatform _platform() => defaultTargetPlatform;
  static List<Locale> _deviceLocales() => PlatformDispatcher.instance.locales;
  static Future<TaroDatabases> _openDatabases() async => (
    journal: JournalDatabase.open(),
    device: DeviceDatabase.open(
      backupExclusion: defaultTargetPlatform == TargetPlatform.iOS
          ? const PlatformBackupExclusion()
          : const NoOpBackupExclusion(),
      logger: const SilentLogger(),
    ),
  );
}

/// The real environment of `main_<flavor>.dart` (RC76): pure delegation
/// to the SDK entry points in [PlatformHooks].
final class ProductionEnvironment implements TaroEnvironment {
  /// The environment of the entrypoint [flavor] (config from
  /// `--dart-define-from-file`).
  ProductionEnvironment(
    Flavor flavor, {
    this.hooks = const PlatformHooks(),
    this.firebaseOptions,
    Map<String, String> defines = FlavorConfig.dartDefines,
  }) : flavor = FlavorConfig.fromDefines(flavor, defines: defines);

  @override
  final FlavorConfig flavor;

  /// The SDK entry points.
  final PlatformHooks hooks;

  /// The flavor's `DefaultFirebaseOptions.currentPlatform` from
  /// `lib/firebase_options_<flavor>.dart` (Phase 10 Sprint 10.2, RC36);
  /// `null` falls back to the native config file. Read inside
  /// [initFirebase], so an unsupported platform only leaves Firebase off.
  final FirebaseOptions Function()? firebaseOptions;

  bool _firebaseReady = false;

  @override
  late final SecureStore secureStore = FlutterSecureStore(
    logger: const SilentLogger(),
  );

  @override
  Future<void> initFirebase() async {
    try {
      await hooks.initializeFirebase(firebaseOptions?.call());
      _firebaseReady = true;
    } on Object {
      // No Firebase project for this build: analytics and crash are NoOp.
      _firebaseReady = false;
    }
  }

  @override
  Future<TaroDatabases> openDatabases() => hooks.openDatabases();

  @override
  Future<List<Override>> buildOverrides(
    FlavorConfig flavor,
    TaroDatabases dbs,
  ) async {
    final inputs = GraphInputs(
      flavor: flavor,
      databases: dbs,
      secureStore: secureStore,
      appInfo: await hooks.loadAppInfo(),
      firebaseReady: _firebaseReady,
      platform: hooks.platform(),
      deviceLocales: hooks.deviceLocales,
      debugAttestationToken: hooks.debugAttestationToken,
      sdks: hooks.sdks,
    );
    return flavor.isProd ? prodOverrides(inputs) : devOverrides(inputs);
  }

  @override
  void installErrorHandlers(CrashReporter crash) =>
      handlers.installErrorHandlers(crash);

  @override
  void runApp(widgets.Widget app) => hooks.runApp(app);
}
