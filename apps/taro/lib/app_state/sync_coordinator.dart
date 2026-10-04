import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/di/providers.dart';
import 'package:taro_core/taro_core.dart';

/// One extra, failure-tolerant step after the [SyncAccount] pass.
typedef SyncStep = Future<void> Function();

/// Runs the launch / resume sync (02 §9.1 step 6, §9.2; AR8, AR14; rule 6)
/// on launch, resume, the reset timer and connectivity regained.
///
/// * **Coalescing:** a run while one is in flight joins it. A resume or
///   connectivity run is skipped only when the last success is younger
///   than `balance.resumeSyncThrottleSec`, the local date and the time zone
///   are unchanged and `now < free.resetsAt` ([SyncAccount.shouldSkip] plus
///   the zone, so a zone change always re-registers it).
/// * **Steps:** the [SyncAccount] pass (token or registration → config →
///   time zone (`409` keeps the server boundary) → balance → purchase
///   outbox drain → pending readings → `pending_acks` → queued erasure →
///   reminder reschedule), then the attestation warm-up (Android) and the
///   Remove Banner Ads ownership refresh. Every step tolerates failure.
/// * [status] feeds the balance chip (`syncing`, `synced`, `stale`,
///   `unavailable`; 01 §7.1).
final class SyncCoordinator {
  /// Creates the coordinator. [locale] gives the reminder copy locale;
  /// [extraSteps] run after the pass, in order.
  SyncCoordinator({
    required SyncAccount account,
    required BalanceRepository balance,
    required RemoteConfigRepository config,
    required TimezoneProvider timezone,
    required Clock clock,
    required Logger logger,
    required String Function() locale,
    List<SyncStep> extraSteps = const [],
  }) : _account = account,
       _balance = balance,
       _config = config,
       _timezone = timezone,
       _clock = clock,
       _logger = logger,
       _locale = locale,
       _extraSteps = List.unmodifiable(extraSteps),
       _current = SyncStatus.stale(lastSyncedAt: balance.cached?.syncedAt);

  final SyncAccount _account;
  final BalanceRepository _balance;
  final RemoteConfigRepository _config;
  final TimezoneProvider _timezone;
  final Clock _clock;
  final Logger _logger;
  final String Function() _locale;
  final List<SyncStep> _extraSteps;

  final StreamController<SyncStatus> _status =
      StreamController<SyncStatus>.broadcast();
  SyncStatus _current;
  Future<SyncStatus>? _inFlight;
  DateTime? _lastSuccessAt;
  String? _lastSuccessLocalDate;
  String? _lastSuccessTimezone;

  /// How many passes actually ran (joins and skips excluded).
  int runs = 0;

  /// The latest status.
  SyncStatus get current => _current;

  /// Status changes (not replayed; read [current] first).
  Stream<SyncStatus> get status => _status.stream;

  /// Whether a pass is running.
  bool get isRunning => _inFlight != null;

  /// Runs a pass for [reason], joins the running one, or skips it (see the
  /// class doc). Never throws.
  Future<SyncStatus> run(SyncReason reason) {
    final running = _inFlight;
    if (running != null) return running;
    final pass = _start(reason);
    _inFlight = pass;
    return pass.whenComplete(() => _inFlight = null);
  }

  Future<SyncStatus> _start(SyncReason reason) async {
    final zone = await _safeZone();
    if (_shouldSkip(reason, zone)) {
      _logger.fine('sync skipped (${reason.name})');
      return _current;
    }
    runs++;
    _emit(const SyncStatus.syncing());
    SyncStatus result;
    try {
      result = await _account(reason, locale: _locale());
    } on Object catch (error, stack) {
      _logger.severe('sync pass failed', error: error, stack: stack);
      result = _fallback(error, stack);
    }
    for (final step in _extraSteps) {
      try {
        await step();
      } on Object catch (error, stack) {
        _logger.warning('sync step failed', error: error, stack: stack);
      }
    }
    if (result is SyncStatusSynced) {
      _lastSuccessAt = _clock.now();
      _lastSuccessLocalDate = LocalDates.format(_clock.nowLocal());
      _lastSuccessTimezone = zone;
    }
    _emit(result);
    return result;
  }

  bool _shouldSkip(SyncReason reason, String? zone) {
    if (zone != _lastSuccessTimezone) return false;
    return SyncAccount.shouldSkip(
      reason: reason,
      now: _clock.now(),
      localDate: LocalDates.format(_clock.nowLocal()),
      config: _config.current,
      lastSuccessAt: _lastSuccessAt,
      lastSuccessLocalDate: _lastSuccessLocalDate,
      balance: _balance.cached,
    );
  }

  Future<String?> _safeZone() async {
    try {
      return await _timezone.currentIana();
    } on Object catch (error) {
      _logger.warning('time zone unreadable', error: error);
      return null;
    }
  }

  SyncStatus _fallback(Object error, StackTrace stack) {
    final cached = _balance.cached;
    return cached == null
        ? SyncStatus.unavailable(
            failure: Failure.unexpected(error: error, stack: stack),
          )
        : SyncStatus.stale(lastSyncedAt: cached.syncedAt);
  }

  void _emit(SyncStatus status) {
    _current = status;
    if (!_status.isClosed) _status.add(status);
  }

  /// Closes [status].
  Future<void> dispose() => _status.close();
}

/// The app's [SyncCoordinator] (keep-alive, one per container). It also
/// runs a connectivity-regained pass whenever the monitor goes online.
final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final removeAds = ref.watch(removeAdsEntitlementProvider);
  final coordinator = SyncCoordinator(
    account: ref.watch(syncAccountProvider),
    balance: ref.watch(balanceRepositoryProvider),
    config: ref.watch(remoteConfigRepositoryProvider),
    timezone: ref.watch(timezoneProvider),
    clock: ref.watch(clockProvider),
    logger: ref.watch(loggerProvider).child('sync'),
    locale: ref.watch(appLocaleProvider),
    extraSteps: [ref.watch(attestationWarmUpProvider), removeAds.refresh],
  );
  var online = true;
  final subscription = ref.watch(connectivityMonitorProvider).online.listen((
    now,
  ) {
    if (now && !online) {
      unawaited(coordinator.run(SyncReason.connectivityRegained));
    }
    online = now;
  });
  ref.onDispose(() async {
    await subscription.cancel();
    await coordinator.dispose();
  });
  return coordinator;
});

/// The balance chip's sync state (01 §7.1): [SyncCoordinator.current] at
/// once, then every change.
base class SyncStatusController extends Notifier<SyncStatus> {
  @override
  SyncStatus build() {
    final coordinator = ref.watch(syncCoordinatorProvider);
    final subscription = coordinator.status.listen((status) => state = status);
    ref.onDispose(subscription.cancel);
    return coordinator.current;
  }
}

/// The app-wide sync status.
final syncStatusProvider = NotifierProvider<SyncStatusController, SyncStatus>(
  SyncStatusController.new,
);
