import 'package:taro_core/src/model/credit_balance.dart';
import 'package:taro_core/src/model/remote_config.dart';
import 'package:taro_core/src/ports/balance_repository.dart';
import 'package:taro_core/src/ports/clock.dart';
import 'package:taro_core/src/ports/install_repository.dart';
import 'package:taro_core/src/ports/logger.dart';
import 'package:taro_core/src/ports/purchase_outbox_drainer.dart';
import 'package:taro_core/src/ports/reading_repository.dart';
import 'package:taro_core/src/ports/reminder_scheduler.dart';
import 'package:taro_core/src/ports/remote_config_repository.dart';
import 'package:taro_core/src/ports/session_token_store.dart';
import 'package:taro_core/src/ports/settings_repository.dart';
import 'package:taro_core/src/ports/sync_reason.dart';
import 'package:taro_core/src/ports/sync_status.dart';
import 'package:taro_core/src/ports/timezone_provider.dart';
import 'package:taro_core/src/result/failure.dart';
import 'package:taro_core/src/result/result.dart';
import 'package:taro_core/src/usecases/delete_all_data.dart';
import 'package:taro_core/src/usecases/resume_reading.dart';

/// One launch/resume sync pass (02 §9.1 step 6, §9.2; rule 6).
///
/// Steps, each idempotent and failure-tolerant (a failed step is logged and
/// the pass continues): token refresh or registration → remote config →
/// time zone → balance → purchase outbox → pending readings → delivery
/// acks → queued server erasure → reminders. `SyncCoordinator` (app)
/// coalesces runs, applies [shouldSkip] and exposes the status stream.
final class SyncAccount {
  /// Creates the use case.
  SyncAccount({
    required InstallRepository install,
    required SessionTokenStore tokens,
    required RemoteConfigRepository config,
    required TimezoneProvider timezone,
    required BalanceRepository balance,
    required PurchaseOutboxDrainer purchases,
    required ResumeReading resume,
    required ReadingRepository readings,
    required DeleteAllData deletion,
    required ReminderScheduler reminders,
    required SettingsRepository settings,
    required Clock clock,
    required Logger logger,
  }) : _install = install,
       _tokens = tokens,
       _config = config,
       _timezone = timezone,
       _balance = balance,
       _purchases = purchases,
       _resume = resume,
       _readings = readings,
       _deletion = deletion,
       _reminders = reminders,
       _settings = settings,
       _clock = clock,
       _logger = logger;

  final InstallRepository _install;
  final SessionTokenStore _tokens;
  final RemoteConfigRepository _config;
  final TimezoneProvider _timezone;
  final BalanceRepository _balance;
  final PurchaseOutboxDrainer _purchases;
  final ResumeReading _resume;
  final ReadingRepository _readings;
  final DeleteAllData _deletion;
  final ReminderScheduler _reminders;
  final SettingsRepository _settings;
  final Clock _clock;
  final Logger _logger;

  /// The resume throttle of 02 §9.2: a resume or connectivity sync is
  /// skipped only if the last success is younger than
  /// `balance.resumeSyncThrottleSec` **and** the local date is unchanged
  /// **and** `now < free.resetsAt`. Launch, reset-boundary, manual and
  /// pre-reading syncs always run.
  static bool shouldSkip({
    required SyncReason reason,
    required DateTime now,
    required String localDate,
    required RemoteConfig config,
    required DateTime? lastSuccessAt,
    required String? lastSuccessLocalDate,
    required CreditBalance? balance,
  }) {
    final throttled =
        reason == SyncReason.resume ||
        reason == SyncReason.connectivityRegained;
    if (!throttled || lastSuccessAt == null || balance == null) return false;
    return now.difference(lastSuccessAt) < config.balanceResumeSyncThrottle &&
        localDate == lastSuccessLocalDate &&
        now.isBefore(balance.free.resetsAt);
  }

  /// Runs one pass with reminder copy in [locale]; returns the balance
  /// chip's status.
  Future<SyncStatus> call(SyncReason reason, {required String locale}) async {
    await _authenticate();
    _logIfErr('config', await _config.refresh());
    await _syncTimezone();
    final synced = await _balance.sync(reason: reason);
    _logIfErr('balance', synced);
    _logIfErr('outbox', await _purchases.drainOutbox(reason: reason));
    _logIfErr('resume', await _resume.resumeAll());
    _logIfErr('acks', await _readings.flushPendingAcks());
    await _deletion.retryQueued();
    await _reminders.schedule(_settings.current.reminder, locale);
    return switch (synced) {
      Ok() => SyncStatus.synced(at: _clock.now()),
      Err(:final failure) => _statusWithout(failure),
    };
  }

  /// Refreshes a token that expires within 24 h; otherwise makes sure the
  /// install is registered.
  Future<void> _authenticate() async {
    final token = (await _tokens.read()).valueOrNull;
    if (token != null && token.needsRefreshAt(_clock.now())) {
      final refreshed = await _install.refreshToken();
      if (refreshed.isOk) return;
      _logIfErr('token', refreshed);
    }
    _logIfErr('register', await _install.ensureRegistered());
  }

  /// Re-registers the free-day time zone when the device zone changed.
  /// `409 TIMEZONE_CHANGE_TOO_SOON` keeps the server boundary.
  Future<void> _syncTimezone() async {
    final current = await _timezone.currentIana();
    final known =
        _balance.cached?.free.timezone ??
        (await _install.getOrCreate()).valueOrNull?.registeredTimezone;
    if (known == null || known == current) return;
    final updated = await _install.updateTimezone(current);
    switch (updated) {
      case Ok(:final value):
        await _balance.apply(value);
      case Err(:final failure):
        _logger.info('timezone kept: ${failure.code}');
    }
  }

  SyncStatus _statusWithout(Failure failure) {
    final cached = _balance.cached;
    return cached == null
        ? SyncStatus.unavailable(failure: failure)
        : SyncStatus.stale(lastSyncedAt: cached.syncedAt);
  }

  void _logIfErr(String step, Result<Object?> result) {
    if (result case Err(:final failure)) {
      _logger.warning('sync step $step failed: ${failure.code}');
    }
  }
}
