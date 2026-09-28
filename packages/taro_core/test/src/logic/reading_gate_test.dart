import 'package:test/test.dart';

import 'logic_support.dart';

final _now = DateTime.utc(2026, 9, 26, 9, 1);

final _registered = InstallIdentity(
  installId: const InstallId('install-1'),
  registeredAt: DateTime.utc(2026, 9),
  trust: Trust.high,
);

const _granted = ConsentState(
  ads: AdsConsent(status: AdsConsentStatus.obtained, canRequestAds: true),
  ai: AiConsent(decision: AiConsentDecision.granted, version: 1),
);

/// One gate input; every field defaults to "passes".
final class _In {
  _In({
    InstallIdentity? install,
    this.balance,
    this.noBalance = false,
    this.config = RemoteConfig.defaults,
    this.consent = _granted,
    this.online = true,
    SpreadDefinition? spread,
    this.regionBlocked = false,
  }) : install = install ?? _registered,
       spread = spread ?? spreadOf(3);

  final InstallIdentity install;
  final CreditBalance? balance;
  final bool noBalance;
  final RemoteConfig config;
  final ConsentState consent;
  final bool online;
  final SpreadDefinition spread;
  final bool regionBlocked;

  GateDecision evaluate() => ReadingGate.evaluate(
    install: install,
    balance: noBalance ? null : balance ?? aBalance(),
    config: config,
    consent: consent,
    online: online,
    spread: spread,
    now: _now,
    aiRegionBlocked: regionBlocked,
  );
}

PaywallOptions _paywallOf(GateDecision d) => switch (d) {
  GateNeedsCredits(:final options) => options,
  _ => throw StateError('not a paywall: $d'),
};

void main() {
  test('GateDecision.kind names every variant once', () {
    const decisions = [
      GateDecision.deviceUnverified(),
      GateDecision.needsAiConsent(),
      GateDecision.offline(),
      GateDecision.readingsPaused(),
      GateDecision.aiUnavailableRegion(),
      GateDecision.spreadDisabled(),
      GateDecision.needsCredits(
        PaywallOptions(
          reason: PaywallReason.noCredits,
          packs: [],
          rewardedAvailable: false,
          nextFreeAt: null,
        ),
      ),
      GateDecision.dailyLimitReached(),
      GateDecision.needsSync(),
      GateDecision.allowed(ChargeSource.free),
    ];
    expect([for (final d in decisions) d.kind], GateDecisionKind.values);
  });

  group('ReadingGate check order (RC44)', () {
    // Each check, in order, as (name, input that fails only this check,
    // expected decision).
    final checks = <(String, _In Function(_In base), GateDecision)>[
      (
        'registration',
        (b) => _In(
          install: const InstallIdentity(installId: InstallId('x')),
          consent: b.consent,
          online: b.online,
          config: b.config,
          spread: b.spread,
          regionBlocked: b.regionBlocked,
          noBalance: b.noBalance,
        ),
        const GateDecision.deviceUnverified(),
      ),
      (
        'AI consent',
        (b) => _In(
          install: b.install,
          consent: const ConsentState(),
          online: b.online,
          config: b.config,
          spread: b.spread,
          regionBlocked: b.regionBlocked,
          noBalance: b.noBalance,
        ),
        const GateDecision.needsAiConsent(),
      ),
      (
        'online',
        (b) => _In(
          install: b.install,
          consent: b.consent,
          online: false,
          config: b.config,
          spread: b.spread,
          regionBlocked: b.regionBlocked,
          noBalance: b.noBalance,
        ),
        const GateDecision.offline(),
      ),
      (
        'readings.enabled',
        (b) => _In(
          install: b.install,
          consent: b.consent,
          online: b.online,
          config: b.config.copyWith(readingsEnabled: false),
          spread: b.spread,
          regionBlocked: b.regionBlocked,
          noBalance: b.noBalance,
        ),
        const GateDecision.readingsPaused(),
      ),
      (
        'region',
        (b) => _In(
          install: b.install,
          consent: b.consent,
          online: b.online,
          config: b.config,
          spread: b.spread,
          regionBlocked: true,
          noBalance: b.noBalance,
        ),
        const GateDecision.aiUnavailableRegion(),
      ),
      (
        'spread enabled',
        (b) => _In(
          install: b.install,
          consent: b.consent,
          online: b.online,
          config: b.config.copyWith(spreadsEnabled: const []),
          spread: b.spread,
          regionBlocked: b.regionBlocked,
          noBalance: b.noBalance,
        ),
        const GateDecision.spreadDisabled(),
      ),
      (
        'balance',
        (b) => _In(
          install: b.install,
          consent: b.consent,
          online: b.online,
          config: b.config,
          spread: b.spread,
          regionBlocked: b.regionBlocked,
          noBalance: true,
        ),
        const GateDecision.needsSync(),
      ),
    ];

    test('all checks passing → allowed', () {
      expect(_In().evaluate(), const GateDecision.allowed(ChargeSource.free));
    });

    for (final (name, fail, expected) in checks) {
      test('only $name fails → $expected', () {
        expect(fail(_In()).evaluate(), expected);
      });
    }

    for (var i = 0; i < checks.length - 1; i++) {
      final (a, failA, expectedA) = checks[i];
      final (b, failB, _) = checks[i + 1];
      test('$a is checked before $b', () {
        expect(failA(failB(_In())).evaluate(), expectedA);
        expect(failB(failA(_In())).evaluate(), expectedA);
      });
    }

    test('the first failing check wins when every check fails', () {
      var input = _In();
      for (final (_, fail, _) in checks.reversed) {
        input = fail(input);
      }
      expect(input.evaluate(), const GateDecision.deviceUnverified());
    });
  });

  group('ReadingGate details', () {
    test('AI consent older than ai.consentVersion is re-asked (RC21)', () {
      final config = RemoteConfig.defaults.copyWith(aiConsentVersion: 2);
      expect(
        _In(config: config).evaluate(),
        const GateDecision.needsAiConsent(),
      );
      final declined = _granted.copyWith(
        ai: const AiConsent(decision: AiConsentDecision.declined, version: 5),
      );
      expect(
        _In(consent: declined).evaluate(),
        const GateDecision.needsAiConsent(),
      );
    });

    test('low trust alone does not block: the balance decides', () {
      final low = _registered.copyWith(trust: Trust.low);
      expect(
        _In(install: low).evaluate(),
        const GateDecision.allowed(ChargeSource.free),
      );
    });

    test('a spread disabled in its own definition is disabled', () {
      expect(
        _In(spread: spreadOf(3, enabled: false)).evaluate(),
        const GateDecision.spreadDisabled(),
      );
    });

    test('a stale balance or one past free.resetsAt needs a sync', () {
      final stale = aBalance(syncedAt: DateTime.utc(2026, 9, 26, 8, 50));
      expect(_In(balance: stale).evaluate(), const GateDecision.needsSync());
      final pastReset = aBalance(resetsAt: DateTime.utc(2026, 9, 26, 9));
      expect(
        _In(balance: pastReset).evaluate(),
        const GateDecision.needsSync(),
      );
    });
  });

  group('ReadingGate balance step', () {
    final cases = <(String, CreditBalance, GateDecision)>[
      (
        'nextSource free',
        aBalance(),
        const GateDecision.allowed(ChargeSource.free),
      ),
      (
        'nextSource bonus',
        aBalance(remaining: 0, bonus: 2, nextSource: ChargeSource.bonus),
        const GateDecision.allowed(ChargeSource.bonus),
      ),
      (
        'nextSource paid',
        aBalance(remaining: 0, paid: 3, nextSource: ChargeSource.paid),
        const GateDecision.allowed(ChargeSource.paid),
      ),
      (
        'no nextSource, free left',
        aBalance(nextSource: null),
        const GateDecision.allowed(ChargeSource.free),
      ),
      (
        'no nextSource, free paused, bonus left',
        aBalance(nextSource: null, paused: true, bonus: 1, paid: 4),
        const GateDecision.allowed(ChargeSource.bonus),
      ),
      (
        'no nextSource, only paid left',
        aBalance(nextSource: null, remaining: 0, paid: 4),
        const GateDecision.allowed(ChargeSource.paid),
      ),
      (
        'canRead but nothing to charge',
        aBalance(nextSource: null, remaining: 0, paid: -2),
        const GateDecision.needsSync(),
      ),
      (
        'dailyLimit',
        aBalance(
          canRead: false,
          canReadReason: CanReadReason.dailyLimit,
          paid: 5,
          nextSource: null,
        ),
        const GateDecision.dailyLimitReached(),
      ),
      (
        'readingsPaused reason',
        aBalance(
          canRead: false,
          canReadReason: CanReadReason.readingsPaused,
          nextSource: null,
          bonus: 1,
          paused: true,
        ),
        const GateDecision.readingsPaused(),
      ),
      (
        'readingsPaused reason, free paused, nothing else',
        aBalance(
          canRead: false,
          canReadReason: CanReadReason.readingsPaused,
          nextSource: null,
          paused: true,
        ),
        const GateDecision.readingsPaused(freePaused: true),
      ),
      (
        'noCredits while free is paused and nothing else (RC64)',
        aBalance(
          canRead: false,
          canReadReason: CanReadReason.noCredits,
          nextSource: null,
          paused: true,
          paid: -1,
        ),
        const GateDecision.readingsPaused(freePaused: true),
      ),
    ];

    for (final (name, balance, expected) in cases) {
      test('$name → $expected', () {
        expect(_In(balance: balance).evaluate(), expected);
      });
    }

    test('noCredits → needsCredits with packs, rewarded, nextFreeAt', () {
      final b = aBalance(
        remaining: 0,
        canRead: false,
        canReadReason: CanReadReason.noCredits,
        nextSource: null,
      );
      final options = _paywallOf(_In(balance: b).evaluate());
      expect(
        options,
        PaywallOptions(
          reason: PaywallReason.noCredits,
          packs: RemoteConfig.defaults.enabledPacks,
          rewardedAvailable: true,
          nextFreeAt: DateTime.utc(2026, 9, 26, 22),
        ),
      );
      expect(options.packs, hasLength(3));
    });

    test('a missing canReadReason is treated as noCredits', () {
      final b = aBalance(remaining: 0, canRead: false, nextSource: null);
      expect(
        _paywallOf(_In(balance: b).evaluate()).reason,
        PaywallReason.noCredits,
      );
    });

    test('lowTrustCap → needsCredits(lowTrustCap), no next free time', () {
      final b = aBalance(
        remaining: 0,
        canRead: false,
        canReadReason: CanReadReason.lowTrustCap,
        nextSource: null,
      );
      final options = _paywallOf(_In(balance: b).evaluate());
      expect(options.reason, PaywallReason.lowTrustCap);
      expect(options.nextFreeAt, isNull);
      expect(options.rewardedAvailable, isTrue);
      expect(options.packs, isNotEmpty);
    });

    test('a zero free limit has no next free time', () {
      final b = aBalance(
        limit: 0,
        remaining: 0,
        canRead: false,
        canReadReason: CanReadReason.noCredits,
        nextSource: null,
      );
      expect(_paywallOf(_In(balance: b).evaluate()).nextFreeAt, isNull);
    });

    test('store.enabled off → no packs (the gate still pays-walls)', () {
      final b = aBalance(
        remaining: 0,
        canRead: false,
        canReadReason: CanReadReason.noCredits,
        nextSource: null,
      );
      final config = RemoteConfig.defaults.copyWith(storeEnabled: false);
      expect(
        _paywallOf(_In(balance: b, config: config).evaluate()).packs,
        isEmpty,
      );
    });

    test('dailyLimitReached never yields a paywall (RC74)', () {
      for (final remaining in [0, 1]) {
        for (final paid in [-1, 0, 5]) {
          for (final paused in [false, true]) {
            final b = aBalance(
              remaining: remaining,
              paid: paid,
              paused: paused,
              canRead: false,
              canReadReason: CanReadReason.dailyLimit,
              nextSource: null,
            );
            expect(
              _In(balance: b).evaluate(),
              const GateDecision.dailyLimitReached(),
            );
          }
        }
      }
    });
  });

  group('PaywallOptions.rewardedAvailable (RC34, RC57, 04 §5.5)', () {
    CreditBalance zeroFree({
      int remaining = 0,
      bool available = true,
      DateTime? cooldownEndsAt,
    }) => aBalance(
      remaining: remaining,
      canRead: false,
      canReadReason: CanReadReason.lowTrustCap,
      nextSource: null,
      rewardedAvailable: available,
      cooldownEndsAt: cooldownEndsAt,
    );

    final cases = <(String, _In, bool)>[
      ('all conditions met', _In(balance: zeroFree()), true),
      (
        'free.remaining > 0 (RC34)',
        _In(balance: zeroFree(remaining: 1)),
        false,
      ),
      (
        'rewarded.available false',
        _In(balance: zeroFree(available: false)),
        false,
      ),
      (
        'UMP cannot request ads',
        _In(
          balance: zeroFree(),
          consent: _granted.copyWith(ads: const AdsConsent()),
        ),
        false,
      ),
      (
        'ads.enabled off',
        _In(
          balance: zeroFree(),
          config: RemoteConfig.defaults.copyWith(adsEnabled: false),
        ),
        false,
      ),
      (
        'rewarded.enabled off',
        _In(
          balance: zeroFree(),
          config: RemoteConfig.defaults.copyWith(rewardedEnabled: false),
        ),
        false,
      ),
      (
        'cooldown running',
        _In(balance: zeroFree(cooldownEndsAt: DateTime.utc(2026, 9, 26, 9, 2))),
        false,
      ),
      (
        'cooldown ended exactly now',
        _In(balance: zeroFree(cooldownEndsAt: _now)),
        true,
      ),
    ];

    for (final (name, input, expected) in cases) {
      test('$name → $expected', () {
        expect(_paywallOf(input.evaluate()).rewardedAvailable, expected);
      });
    }

    test('offline is false (paywall() used after a hold 402)', () {
      final options = ReadingGate.paywall(
        zeroFree(),
        RemoteConfig.defaults,
        _granted,
        reason: PaywallReason.noCredits,
        online: false,
        now: _now,
      );
      expect(options.rewardedAvailable, isFalse);
    });
  });
}
