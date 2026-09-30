import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:taro/services/logging/redactor.dart';
import 'package:taro_core/taro_core.dart';

/// Crashlytics custom keys (02 §13).
abstract final class CrashKeys {
  /// The build flavor (`dev`, `staging`, `prod`).
  static const String flavor = 'flavor';

  /// The app locale tag.
  static const String locale = 'locale';

  /// The balance sync state (`syncing`, `synced`, `stale`, `unavailable`).
  static const String syncStatus = 'sync_status';

  /// The last route the router showed.
  static const String lastRoute = 'last_route';
}

/// The production `CrashReporter` over Firebase Crashlytics (02 §5, §13).
/// The only file importing `firebase_crashlytics`.
///
/// Collection is bound to the analytics toggle ([setCollectionEnabled]);
/// while it is off nothing is recorded. Every `UnexpectedFailure` is
/// reported non-fatal with its original error and stack. Error text,
/// context and breadcrumbs go through the [Redactor] first. Reporting never
/// throws: a Crashlytics failure is swallowed, because logging it would come
/// back here through the breadcrumb sink.
final class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter._(this._crashlytics, this._redactor, this._enabled);

  /// [create] over the plugin singleton (after `Firebase.initializeApp`).
  static Future<FirebaseCrashReporter> fromPlugin({
    required String flavor,
    required bool collectionEnabled,
    required Redactor redactor,
  }) => create(
    FirebaseCrashlytics.instance,
    flavor: flavor,
    collectionEnabled: collectionEnabled,
    redactor: redactor,
  );

  /// Creates the reporter over [crashlytics] (`FirebaseCrashlytics.instance`
  /// in production), applies [collectionEnabled] and sets the `flavor` key.
  static Future<FirebaseCrashReporter> create(
    FirebaseCrashlytics crashlytics, {
    required String flavor,
    required bool collectionEnabled,
    required Redactor redactor,
  }) async {
    final reporter = FirebaseCrashReporter._(
      crashlytics,
      redactor,
      collectionEnabled,
    );
    await reporter._guard(
      () => crashlytics.setCrashlyticsCollectionEnabled(collectionEnabled),
    );
    await reporter._setKey(CrashKeys.flavor, flavor);
    return reporter;
  }

  final FirebaseCrashlytics _crashlytics;
  final Redactor _redactor;
  bool _enabled;

  /// Whether reports are collected.
  bool get collectionEnabled => _enabled;

  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
    Map<String, Object> context = const {},
  }) async {
    if (!_enabled) return;
    final (reported, trace, isFatal) = switch (error) {
      UnexpectedFailure(error: final inner, stack: final innerStack) => (
        inner,
        innerStack,
        false,
      ),
      _ => (error, stack, fatal),
    };
    final information = [
      for (final MapEntry(:key, :value) in _redactor.redactMap(context).entries)
        '$key=$value',
    ];
    await _guard(
      () => _crashlytics.recordError(
        _RedactedError(reported.runtimeType, _redactor.redact('$reported')),
        trace,
        information: information,
        printDetails: false,
        fatal: isFatal,
      ),
    );
  }

  /// Reports [failure] non-fatal when it is an `UnexpectedFailure`; mapped
  /// failures are expected outcomes and are not reported.
  Future<void> recordFailure(Failure failure) async {
    if (failure is UnexpectedFailure) {
      await recordError(failure, failure.stack);
    }
  }

  @override
  void log(String breadcrumb) {
    if (!_enabled) return;
    unawaited(_guard(() => _crashlytics.log(_redactor.redact(breadcrumb))));
  }

  @override
  Future<void> setCollectionEnabled({required bool enabled}) async {
    _enabled = enabled;
    await _guard(() => _crashlytics.setCrashlyticsCollectionEnabled(enabled));
  }

  /// Sets the `locale` key.
  Future<void> setLocale(String localeTag) =>
      _setKey(CrashKeys.locale, localeTag);

  /// Sets the `sync_status` key.
  Future<void> setSyncStatus(SyncStatus status) => _setKey(
    CrashKeys.syncStatus,
    switch (status) {
      SyncStatusSyncing() => 'syncing',
      SyncStatusSynced() => 'synced',
      SyncStatusStale() => 'stale',
      SyncStatusUnavailable(:final failure) => 'unavailable:${failure.code}',
    },
  );

  /// Sets the `last_route` key (redacted: routes may carry IDs).
  Future<void> setLastRoute(String route) =>
      _setKey(CrashKeys.lastRoute, _redactor.redact(route));

  Future<void> _setKey(String key, String value) =>
      _guard(() => _crashlytics.setCustomKey(key, value));

  Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } on Object {
      // Best effort by design (see the class doc): a report that cannot be
      // delivered is lost rather than looping through the logger.
    }
  }
}

/// The redacted stand-in handed to Crashlytics, which reports
/// `exception.toString()`.
final class _RedactedError {
  const _RedactedError(this.type, this.text);

  final Type type;
  final String text;

  @override
  String toString() => text.startsWith('$type') ? text : '$type: $text';
}
