import 'dart:async';
import 'dart:convert';

import 'package:taro/data/db/device/cache_dao.dart';
import 'package:taro/data/db/device/device_database.dart';
import 'package:taro/data/repositories/serial_value.dart';
import 'package:taro_core/taro_core.dart';

/// [ConsentStore] over the single `consent_state` row of `taro_device.db`
/// (02 §5, §9.7, RC75): never backed up or exported, so consent is asked
/// again after an OS restore.
///
/// An empty table reads as `ConsentState()` (the first-launch state). The
/// row holds [encode]'s JSON; an unknown enum name or a mistyped field
/// reads as that field's default. Updates run one after another; a row
/// cleared outside the store ("Delete all data") is reloaded.
final class ConsentStoreImpl implements ConsentStore {
  ConsentStoreImpl._(this._dao, this._clock, this._logger);

  /// Opens the store with the stored state loaded.
  static Future<ConsentStoreImpl> open({
    required CacheDao cache,
    required Clock clock,
    required Logger logger,
  }) async {
    final store = ConsentStoreImpl._(cache, clock, logger);
    store._value.set(await store._load());
    store._value.follow(
      cache.watchConsent(),
      store._load,
      onError: (error, stack) =>
          logger.warning('consent reload failed', error: error),
    );
    return store;
  }

  final CacheDao _dao;
  final Clock _clock;
  final Logger _logger;
  final SerialValue<ConsentState> _value = SerialValue(const ConsentState());

  @override
  ConsentState get current => _value.value;

  @override
  Stream<ConsentState> watch() => _value.watch();

  @override
  Future<Result<ConsentState>> update(
    ConsentState Function(ConsentState current) change,
  ) => _value.serial(() async {
    try {
      final next = change(_value.value);
      await _dao.putConsent(
        ConsentStatesCompanion.insert(
          json: jsonEncode(encode(next)),
          updatedAt: _clock.now(),
        ),
      );
      _value.set(next);
      return Result.ok(next);
    } on Object catch (error) {
      _logger.severe('consent update failed', error: error);
      return const Result.err(Failure.storage());
    }
  });

  /// Stops following the row and completes [watch] streams.
  Future<void> close() => _value.close();

  Future<ConsentState> _load() async {
    final row = await _dao.consent();
    if (row == null) return const ConsentState();
    try {
      return decode(jsonDecode(row.json));
    } on FormatException catch (error) {
      _logger.warning(
        'consent row unreadable; first-launch state used',
        error: error,
      );
      return const ConsentState();
    }
  }

  /// The stored JSON of [state].
  static Map<String, Object?> encode(ConsentState state) => {
    'ads': {
      'status': state.ads.status.name,
      'canRequestAds': state.ads.canRequestAds,
      'privacyOptionsRequired': state.ads.privacyOptionsRequired,
    },
    'tracking': state.tracking.name,
    'ai': {
      'decision': state.ai.decision.name,
      'version': state.ai.version,
      'at': state.ai.at?.toUtc().toIso8601String(),
    },
    'analyticsEnabled': state.analyticsEnabled,
    'onboardingStep': state.onboardingStep.name,
  };

  /// The state of stored [json]; a missing, unknown or mistyped field takes
  /// its default.
  static ConsentState decode(Object? json) {
    const d = ConsentState();
    final root = _map(json);
    final ads = _map(root['ads']);
    final ai = _map(root['ai']);
    final at = ai['at'];
    return ConsentState(
      ads: AdsConsent(
        status: _enum(ads['status'], AdsConsentStatus.values, d.ads.status),
        canRequestAds: _bool(ads['canRequestAds'], d.ads.canRequestAds),
        privacyOptionsRequired: _bool(
          ads['privacyOptionsRequired'],
          d.ads.privacyOptionsRequired,
        ),
      ),
      tracking: _enum(root['tracking'], TrackingStatus.values, d.tracking),
      ai: AiConsent(
        decision: _enum(
          ai['decision'],
          AiConsentDecision.values,
          d.ai.decision,
        ),
        version: ai['version'] is int ? ai['version']! as int : null,
        at: at is String ? DateTime.tryParse(at)?.toUtc() : null,
      ),
      analyticsEnabled: _bool(root['analyticsEnabled'], d.analyticsEnabled),
      onboardingStep: _enum(
        root['onboardingStep'],
        OnboardingStep.values,
        d.onboardingStep,
      ),
    );
  }

  static Map<String, Object?> _map(Object? value) =>
      value is Map<String, Object?> ? value : const {};

  static bool _bool(Object? value, bool fallback) =>
      value is bool ? value : fallback;

  static T _enum<T extends Enum>(Object? value, List<T> values, T fallback) =>
      value is String ? values.asNameMap()[value] ?? fallback : fallback;
}
