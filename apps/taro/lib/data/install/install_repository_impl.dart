import 'dart:async';
import 'dart:convert';

import 'package:taro/data/api/dto/install_dtos.dart';
import 'package:taro/data/api/worker_client.dart';
import 'package:taro/data/api/worker_models.dart';
import 'package:taro/data/db/device/cache_dao.dart';
import 'package:taro/data/install/install_secret.dart';
import 'package:taro/data/install/proof_of_work.dart';
import 'package:taro/data/secure/keys.dart';
import 'package:taro_core/taro_core.dart';

/// Called with every successful `POST /v1/installs` (the embedded balance
/// and config, for the caches of Sprint 11.4).
typedef RegistrationListener = Future<void> Function(Registration registration);

/// The [InstallRepository] over secure storage and the Worker (02 §6.2,
/// §6.4, 03 §3).
///
/// * The install ID and the 32-byte install secret live in secure storage
///   and are written together before anything else; a secure-storage
///   error is a [StorageFailure] and never yields a second ID.
/// * The registration outcome (instant, trust, zone) is a `sync_state`
///   marker in `taro_device.db`, which is excluded from OS backup. After an
///   iOS reinstall the Keychain keeps the ID and secret but the marker and
///   the App Attest key are gone, so [ensureRegistered] re-registers with
///   the same ID and secret (RC54).
/// * Every registration attempt carries a fresh `Idempotency-Key`; the
///   client's retry of a network failure reuses it (RC55).
/// * The install secret is sent only in `POST /v1/installs` and is never
///   logged; neither is the install ID or a token.
final class InstallRepositoryImpl implements InstallRepository {
  /// Creates the repository. [solveProofOfWork] runs the `type: none`
  /// proof of work (a background isolate by default).
  InstallRepositoryImpl({
    required WorkerClient client,
    required WorkerClientConfig config,
    required SecureStore secure,
    required CacheDao cache,
    required AttestationService attestation,
    required TimezoneProvider timezone,
    required Clock clock,
    required IdGenerator ids,
    required RandomSource random,
    required Logger logger,
    ProofOfWorkSolver solveProofOfWork = solveProofOfWorkInIsolate,
    RegistrationListener? onRegistered,
  }) : _client = client,
       _config = config,
       _secure = secure,
       _cache = cache,
       _attestation = attestation,
       _timezone = timezone,
       _clock = clock,
       _ids = ids,
       _random = random,
       _logger = logger.child('install'),
       _solveProofOfWork = solveProofOfWork,
       _onRegistered = onRegistered;

  /// The `sync_state` key of the registration marker.
  static const String registrationKey = 'install_registration';

  /// How long an install repaired to low trust (its platform key could not
  /// sign) skips the App Attest upgrade, so a device whose App Attest keeps
  /// failing does not spend its daily re-registrations on every launch.
  static const Duration upgradePauseAfterRepair = Duration(days: 7);

  final WorkerClient _client;
  final WorkerClientConfig _config;
  final SecureStore _secure;
  final CacheDao _cache;
  final AttestationService _attestation;
  final TimezoneProvider _timezone;
  final Clock _clock;
  final IdGenerator _ids;
  final RandomSource _random;
  final Logger _logger;
  final ProofOfWorkSolver _solveProofOfWork;
  final RegistrationListener? _onRegistered;

  _Install? _install;
  Future<Result<_Install>>? _loading;
  Future<Result<InstallIdentity>>? _registering;
  bool _upgradeTried = false;

  /// Whether a platform key was attested in this launch (a repair then
  /// goes straight to low trust: a fresh key that cannot sign is not lost,
  /// the platform is failing).
  bool _attestedThisLaunch = false;

  /// Whether a repair with a new platform key was already tried in this
  /// launch.
  bool _platformRepairTried = false;

  @override
  Future<Result<InstallIdentity>> getOrCreate() async =>
      (await _load()).map((install) => install.identity);

  @override
  Future<Result<InstallIdentity>> ensureRegistered() async {
    final loaded = await _load();
    return loaded.then((install) async {
      final identity = install.identity;
      if (!identity.isRegistered) return _registerOnce();
      if (_canUpgrade(identity)) return _upgrade(identity);
      return Result.ok(identity);
    });
  }

  /// An iOS install registered without an App Attest key (low trust: App
  /// Attest was unavailable, or not yet probed, at that registration) tries
  /// once per launch to re-register with App Attest (same ID and secret).
  bool _canUpgrade(InstallIdentity identity) =>
      !_upgradeTried &&
      _config.platform == AppPlatform.ios &&
      identity.trust == Trust.low &&
      identity.attestationKeyId == null &&
      !_upgradePaused;

  bool get _upgradePaused {
    final until = _install?.upgradeAfter;
    return until != null && _clock.now().isBefore(until);
  }

  /// The upgrade of [_canUpgrade]. It reaches the Worker only with a
  /// platform attestation; otherwise, or on any failure, the low-trust
  /// registration stays as it is.
  Future<Result<InstallIdentity>> _upgrade(InstallIdentity identity) async {
    _upgradeTried = true;
    final upgraded = await (_registering ??= _register(
      mode: _AttestMode.platformOnly,
    ).whenComplete(() => _registering = null));
    if (upgraded case Err(:final failure)) {
      _logger.info('low-trust install kept: ${failure.code}');
      return Result.ok(identity);
    }
    return upgraded;
  }

  /// Registers again with the same install ID and secret (02 §6.4): after
  /// `AttestationFailure(keyInvalidated)` (a reinstall or OS restore lost
  /// the App Attest key) or an expired session. The stored key ID and
  /// registration marker are dropped first, so a crash mid-way re-runs
  /// the registration on the next launch.
  Future<Result<InstallIdentity>> reRegister() async {
    final loaded = await _load();
    return loaded.then((install) async {
      if (_registering case final running?) return running;
      _logger.info('re-registering the install');
      final cleared = await _clearRegistration(install);
      if (cleared case Err(:final failure)) return Result.err(failure);
      // A platform that cannot attest now falls back to low trust instead of
      // leaving the install unregistered.
      return _registering ??= _register(
        mode: _AttestMode.repair,
      ).whenComplete(() => _registering = null);
    });
  }

  @override
  Future<Result<InstallIdentity>> repairRegistration() async {
    final loaded = await _load();
    return loaded.then((install) async {
      if (_registering case final running?) return running;
      final withPlatform =
          _config.platform == AppPlatform.ios &&
          !_attestedThisLaunch &&
          !_platformRepairTried;
      if (withPlatform) _platformRepairTried = true;
      final mode = withPlatform ? _AttestMode.repair : _AttestMode.noneOnly;
      _logger.info('repairing the registration (${mode.name})');
      final repaired = await (_registering ??= _register(
        mode: mode,
      ).whenComplete(() => _registering = null));
      switch (repaired) {
        case Ok(:final value) when value.attestationKeyId == null:
          await _pauseUpgrade();
        case Ok():
          break;
        case Err(:final failure):
          _logger.severe('registration repair failed: ${failure.code}');
      }
      return repaired;
    });
  }

  /// Pauses the App Attest upgrade for [upgradePauseAfterRepair].
  Future<void> _pauseUpgrade() async {
    final install = _install;
    if (install == null) return;
    _install = install.copyWith(
      upgradeAfter: _clock.now().add(upgradePauseAfterRepair),
    );
    await _updateMarker((marker) => marker);
  }

  @override
  Future<Result<void>> refreshToken() async {
    final result = await _client.refreshToken();
    switch (result) {
      case Ok(:final value):
        await _updateMarker((marker) => marker.copyWith(trust: value.trust));
        return const Result.ok(null);
      case Err(
            failure: AttestationFailure(
              kind: AttestationFailureKind.keyInvalidated,
            ),
          ) ||
          Err(failure: SessionExpiredFailure()):
        _logger.warning(
          'token refresh needs re-registration: '
          '${result.failureOrNull!.code}',
        );
        return (await reRegister()).map((_) {});
      case Err(:final failure):
        return Result.err(failure);
    }
  }

  @override
  Future<Result<CreditBalance>> updateTimezone(String iana) async {
    final result = await _client.updateTimezone(
      iana,
      idempotencyKey: _ids.uuidV4(),
    );
    switch (result) {
      case Ok():
        await _updateMarker((marker) => marker.copyWith(timezone: iana));
      case Err(failure: TimezoneChangeRejectedFailure(:final allowedAfter)):
        // Keep the server boundary (03 §3.5): its `resetsAt` stays in use.
        _logger.info('timezone change rejected until $allowedAfter');
      case Err():
        break;
    }
    return result;
  }

  // Identity ----------------------------------------------------------------

  Future<Result<_Install>> _load() async {
    if (_install case final install?) return Result.ok(install);
    return _loading ??= _read().whenComplete(() => _loading = null);
  }

  Future<Result<_Install>> _read() async {
    try {
      final storedId = _value(await _secure.read(SecureKeys.installId));
      final storedSecret = _value(await _secure.read(SecureKeys.installSecret));
      final binding = _value(await _secure.read(SecureKeys.purchaseBinding));
      final keyId = _value(await _secure.read(SecureKeys.attestKeyId));

      final installId = storedId ?? _ids.uuidV4();
      final secret = storedSecret ?? generateInstallSecret(_random);
      // The ID and the secret are written together, before anything else.
      if (storedId == null) {
        _value(await _secure.write(SecureKeys.installId, installId));
      }
      if (storedSecret == null) {
        _value(await _secure.write(SecureKeys.installSecret, secret));
      }
      if (storedId == null) {
        _logger.info('install identity created');
      } else if (storedSecret == null) {
        _logger.warning('install secret was missing; a new one was stored');
      }

      final marker = _RegistrationMarker.decode(
        await _cache.syncValue(registrationKey),
        installId: installId,
      );
      final install = _Install(
        secret: secret,
        upgradeAfter: marker?.upgradeAfter,
        identity: InstallIdentity(
          installId: InstallId(installId),
          registeredAt: marker?.registeredAt,
          registeredTimezone: marker?.timezone,
          trust: marker?.trust,
          purchaseBinding: marker == null ? null : _decodeBinding(binding),
          attestationKeyId: keyId,
        ),
      );
      return Result.ok(_install = install);
    } on _StorageError {
      return const Result.err(Failure.storage());
    } on Object catch (error) {
      _logger.severe('install identity unreadable: ${error.runtimeType}');
      return const Result.err(Failure.storage());
    }
  }

  // Registration ------------------------------------------------------------

  Future<Result<InstallIdentity>> _registerOnce() =>
      _registering ??= _register().whenComplete(() => _registering = null);

  /// One registration attempt in [mode] (see [_AttestMode]).
  Future<Result<InstallIdentity>> _register({
    _AttestMode mode = _AttestMode.standard,
  }) async {
    final install = _install!;
    final installId = install.identity.installId.value;

    final ChallengeDto dto;
    switch (await _client.challenge()) {
      case Ok(:final value):
        dto = value;
      case Err(:final failure):
        return _registerFailed(failure);
    }

    final signal = await _attestation.deviceSignal();
    final RegistrationAttestationDto attestation;
    final String? keyId;
    switch (await _attest(dto, installId, signal, mode: mode)) {
      case Ok(value: (final body, final id)):
        (attestation, keyId) = (body, id);
      case Err(:final failure):
        return _registerFailed(failure);
    }

    final body = RegisterRequestDto(
      installId: installId,
      installSecret: install.secret,
      platform: _config.platform.name,
      appVersion: _config.appVersion,
      locale: _config.locale(),
      timezone: await _timezone.currentIana(),
      deviceCheckToken: signal.deviceCheckToken,
      deviceKey: signal.deviceKey,
      attestation: attestation,
    );
    // A fresh key per registration attempt (RC55).
    final result = await _client.register(body, idempotencyKey: _ids.uuidV4());
    return result.then((registration) async {
      final stored = await _store(install, registration, body.timezone, keyId);
      if (stored case Ok()) {
        _logger.info('install registered (trust: ${registration.trust.name})');
        await _onRegistered?.call(registration);
      }
      return stored;
    });
  }

  Result<InstallIdentity> _registerFailed(Failure failure) {
    _logger.warning('install registration failed: ${failure.code}');
    return Result.err(failure);
  }

  /// The registration attestation: the platform one, or `type: none` with a
  /// proof of work when the platform has none (03 §3.3). The platform proof
  /// binds [installId] and the device [signal] (02 §6.4, 03 §3.7).
  ///
  /// There is no `isSupported` pre-check: the platform adapter settles it in
  /// its warm-up, which [AttestationService.attest] awaits and which may not
  /// have run yet (it did not on a first launch, so every new install
  /// registered as `type: none`). An adapter without platform attestation
  /// answers a `none` blob, which becomes the proof-of-work `none` here.
  Future<Result<_Attested>> _attest(
    ChallengeDto dto,
    String installId,
    DeviceSignal signal, {
    required _AttestMode mode,
  }) async {
    if (mode == _AttestMode.noneOnly) {
      return Result.ok(await _none(dto, installId, 'error'));
    }
    final result = await _attestation.attest(
      challenge: dto.challenge,
      installId: installId,
      signal: signal,
    );
    if (mode == _AttestMode.platformOnly) {
      return switch (result) {
        Ok(:final value) when value.type != AttestationType.none => Result.ok((
          RegistrationAttestationDto.fromBlob(value),
          value.keyId,
        )),
        Ok() => const Result.err(
          Failure.attestation(kind: AttestationFailureKind.unsupported),
        ),
        Err(:final failure) => Result.err(failure),
      };
    }
    switch (result) {
      case Ok(:final value) when value.type == AttestationType.none:
        return Result.ok(await _none(dto, installId, 'unsupported'));
      case Ok(:final value):
        return Result.ok((
          RegistrationAttestationDto.fromBlob(value),
          value.type == AttestationType.appAttest ? value.keyId : null,
        ));
      case Err(
        failure: AttestationFailure(kind: AttestationFailureKind.unsupported),
      ):
        return Result.ok(await _none(dto, installId, 'unsupported'));
      case Err(
        failure: AttestationFailure(
          kind: AttestationFailureKind.transient ||
              AttestationFailureKind.quota,
        ),
      ):
        _logger.warning('platform attestation unavailable; low trust');
        return Result.ok(await _none(dto, installId, 'error'));
      case Err(:final AttestationFailure failure)
          when mode == _AttestMode.repair:
        _logger.severe(
          'platform attestation failed in a repair: ${failure.kind.name}; '
          'low trust',
        );
        return Result.ok(await _none(dto, installId, 'error'));
      case Err(:final failure):
        return Result.err(failure);
    }
  }

  Future<_Attested> _none(
    ChallengeDto dto,
    String installId,
    String reason,
  ) async {
    final pow = await _solveProofOfWork(
      challenge: dto.challenge,
      installId: installId,
      bits: dto.powBits,
    );
    return (
      RegistrationAttestationDto.fromBlob(
        AttestationBlob(type: AttestationType.none, challenge: dto.challenge),
        reason: reason,
        pow: pow,
      ),
      null,
    );
  }

  /// Persists a registration: purchase binding, App Attest key ID, then the
  /// marker (last, so a partial write re-registers on the next launch). The
  /// client already stored the token.
  Future<Result<InstallIdentity>> _store(
    _Install install,
    Registration registration,
    String timezone,
    String? keyId,
  ) async {
    final marker = _RegistrationMarker(
      installId: install.identity.installId.value,
      registeredAt: _clock.now(),
      trust: registration.trust,
      timezone: timezone,
      upgradeAfter: install.upgradeAfter,
    );
    try {
      _value(
        await _secure.write(
          SecureKeys.purchaseBinding,
          _encodeBinding(registration.purchaseBinding),
        ),
      );
      // A registration without a key replaces the Worker's stored key
      // (03 §3.3), so a stale local key ID must not sign later calls.
      _value(
        keyId != null
            ? await _secure.write(SecureKeys.attestKeyId, keyId)
            : await _secure.delete(SecureKeys.attestKeyId),
      );
      await _cache.putSyncValue(registrationKey, marker.encode());
    } on _StorageError {
      return const Result.err(Failure.storage());
    } on Object catch (error) {
      _logger.severe('registration marker write failed: ${error.runtimeType}');
      return const Result.err(Failure.storage());
    }
    final identity = install.identity.copyWith(
      registeredAt: marker.registeredAt,
      registeredTimezone: timezone,
      trust: registration.trust,
      purchaseBinding: registration.purchaseBinding,
      attestationKeyId: keyId,
    );
    if (keyId != null) _attestedThisLaunch = true;
    _install = install.copyWith(identity: identity);
    return Result.ok(identity);
  }

  Future<Result<void>> _clearRegistration(_Install install) async {
    try {
      await _cache.removeSyncValue(registrationKey);
      _value(await _secure.delete(SecureKeys.attestKeyId));
    } on _StorageError {
      return const Result.err(Failure.storage());
    } on Object catch (error) {
      _logger.severe('registration marker clear failed: ${error.runtimeType}');
      return const Result.err(Failure.storage());
    }
    _install = install.copyWith(
      identity: InstallIdentity(installId: install.identity.installId),
    );
    return const Result.ok(null);
  }

  /// Applies [update] to the stored marker of a registered install. A
  /// failed write is logged: the Worker already holds the new value.
  Future<void> _updateMarker(
    _RegistrationMarker Function(_RegistrationMarker marker) update,
  ) async {
    final install = _install;
    final identity = install?.identity;
    if (install == null || identity == null || !identity.isRegistered) return;
    final marker = update(
      _RegistrationMarker(
        installId: identity.installId.value,
        registeredAt: identity.registeredAt!,
        trust: identity.trust!,
        timezone: identity.registeredTimezone!,
        upgradeAfter: install.upgradeAfter,
      ),
    );
    _install = install.copyWith(
      identity: identity.copyWith(
        trust: marker.trust,
        registeredTimezone: marker.timezone,
      ),
    );
    try {
      await _cache.putSyncValue(registrationKey, marker.encode());
    } on Object catch (error) {
      _logger.warning(
        'registration marker update failed: '
        '${error.runtimeType}',
      );
    }
  }

  // Encoding ----------------------------------------------------------------

  static String _encodeBinding(PurchaseBinding binding) => jsonEncode({
    'appleAccountToken': ?binding.appleAccountToken,
    'playAccountId': ?binding.playAccountId,
  });

  PurchaseBinding? _decodeBinding(String? raw) {
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return PurchaseBinding(
        appleAccountToken: json['appleAccountToken'] as String?,
        playAccountId: json['playAccountId'] as String?,
      );
    } on Object catch (error) {
      _logger.warning(
        'stored purchase binding unreadable: '
        '${error.runtimeType}',
      );
      return null;
    }
  }

  /// The value of [result]; a failure aborts the operation as a storage
  /// error.
  static T _value<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err() => throw const _StorageError(),
  };
}

/// A registration attestation body and the App Attest key ID it used.
typedef _Attested = (RegistrationAttestationDto, String?);

/// Thrown inside the repository only, for a failed secure-storage call.
final class _StorageError implements Exception {
  const _StorageError();
}

/// The loaded identity plus the secret (kept out of [InstallIdentity]).
final class _Install {
  const _Install({
    required this.secret,
    required this.identity,
    this.upgradeAfter,
  });

  final String secret;
  final InstallIdentity identity;

  /// No App Attest upgrade before this instant (after a low-trust repair).
  final DateTime? upgradeAfter;

  _Install copyWith({InstallIdentity? identity, DateTime? upgradeAfter}) =>
      _Install(
        secret: secret,
        identity: identity ?? this.identity,
        upgradeAfter: upgradeAfter ?? this.upgradeAfter,
      );
}

/// How a registration attests (03 §3.3).
enum _AttestMode {
  /// The platform attestation, else `type: none` when the platform has none
  /// or is unavailable (a first registration).
  standard,

  /// The platform attestation only (the low → high upgrade).
  platformOnly,

  /// A new platform key, else `type: none` on any attestation failure.
  repair,

  /// `type: none` only (the platform cannot sign on this device now).
  noneOnly,
}

/// The `install_registration` `sync_state` marker.
final class _RegistrationMarker {
  const _RegistrationMarker({
    required this.installId,
    required this.registeredAt,
    required this.trust,
    required this.timezone,
    this.upgradeAfter,
  });

  final String installId;
  final DateTime registeredAt;
  final Trust trust;
  final String timezone;
  final DateTime? upgradeAfter;

  _RegistrationMarker copyWith({Trust? trust, String? timezone}) =>
      _RegistrationMarker(
        installId: installId,
        registeredAt: registeredAt,
        trust: trust ?? this.trust,
        timezone: timezone ?? this.timezone,
        upgradeAfter: upgradeAfter,
      );

  String encode() => jsonEncode({
    'installId': installId,
    'registeredAt': registeredAt.toUtc().toIso8601String(),
    'trust': trust.name,
    'timezone': timezone,
    'upgradeAfter': ?upgradeAfter?.toUtc().toIso8601String(),
  });

  /// The marker in [raw] when it belongs to [installId]; a marker of
  /// another ID or an unreadable one counts as "not registered".
  static _RegistrationMarker? decode(String? raw, {required String installId}) {
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['installId'] != installId) return null;
      return _RegistrationMarker(
        installId: installId,
        registeredAt: DateTime.parse(json['registeredAt'] as String).toUtc(),
        trust: Trust.values.byName(json['trust'] as String),
        timezone: json['timezone'] as String,
        upgradeAfter: switch (json['upgradeAfter']) {
          final String at => DateTime.parse(at).toUtc(),
          _ => null,
        },
      );
    } on Object {
      return null;
    }
  }
}
