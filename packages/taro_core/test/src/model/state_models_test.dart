import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

void main() {
  group('Entitlement', () {
    test('only owned removes ads', () {
      expect(Entitlement.unknown.removesAds, isFalse);
      expect(Entitlement.unknown.source, EntitlementSource.cache);
      const owned = Entitlement(
        removeAds: EntitlementState.owned,
        source: EntitlementSource.cache,
      );
      expect(owned.removesAds, isTrue);
      expect(
        owned.copyWith(removeAds: EntitlementState.notOwned).removesAds,
        isFalse,
      );
      final verified = owned.copyWith(
        source: EntitlementSource.store,
        verifiedAt: DateTime.utc(2026),
      );
      expect(verified, isNot(owned));
      expect(verified.verifiedAt, DateTime.utc(2026));
    });
  });

  group('ConsentState', () {
    test('first-launch defaults', () {
      const state = ConsentState();
      expect(state.ads.status, AdsConsentStatus.unknown);
      expect(state.ads.canRequestAds, isFalse);
      expect(state.ads.privacyOptionsRequired, isFalse);
      expect(state.tracking, TrackingStatus.notDetermined);
      expect(state.ai.decision, AiConsentDecision.unknown);
      expect(state.analyticsEnabled, isFalse);
      expect(state.onboardingStep, OnboardingStep.welcome);
      expect(state.onboardingDone, isFalse);
      expect(
        state.copyWith(onboardingStep: OnboardingStep.done).onboardingDone,
        isTrue,
      );
    });

    final at = DateTime.utc(2026, 9, 26);
    final table = <String, (AiConsent, int, bool)>{
      'unknown': (const AiConsent(), 1, false),
      'declined': (
        AiConsent(decision: AiConsentDecision.declined, version: 1, at: at),
        1,
        false,
      ),
      'granted without version': (
        const AiConsent(decision: AiConsentDecision.granted),
        1,
        false,
      ),
      'granted, same version': (
        AiConsent(decision: AiConsentDecision.granted, version: 1, at: at),
        1,
        true,
      ),
      'granted, newer version': (
        AiConsent(decision: AiConsentDecision.granted, version: 2, at: at),
        1,
        true,
      ),
      'granted, version bumped (RC21)': (
        AiConsent(decision: AiConsentDecision.granted, version: 1, at: at),
        2,
        false,
      ),
    };
    for (final MapEntry(key: name, value: row) in table.entries) {
      test('AiConsent.isValidFor: $name', () {
        expect(row.$1.isValidFor(row.$2), row.$3);
      });
    }

    test('value equality and copyWith of parts', () {
      const state = ConsentState();
      final updated = state.copyWith(
        ads: state.ads.copyWith(
          status: AdsConsentStatus.obtained,
          canRequestAds: true,
        ),
        ai: state.ai.copyWith(decision: AiConsentDecision.granted, version: 1),
        tracking: TrackingStatus.authorized,
        analyticsEnabled: true,
      );
      expect(updated, isNot(state));
      expect(updated.ads.canRequestAds, isTrue);
      expect(const ConsentState(), state);
    });
  });

  group('InstallIdentity', () {
    test('registration and binding', () {
      const fresh = InstallIdentity(installId: InstallId('i-1'));
      expect(fresh.isRegistered, isFalse);
      final registered = fresh.copyWith(
        registeredAt: DateTime.utc(2026),
        registeredTimezone: 'Europe/Berlin',
        trust: Trust.high,
        purchaseBinding: const PurchaseBinding(appleAccountToken: 'uuid'),
        attestationKeyId: 'key',
      );
      expect(registered.isRegistered, isTrue);
      expect(registered.purchaseBinding!.appleAccountToken, 'uuid');
      expect(
        registered.purchaseBinding!.copyWith(playAccountId: 'p').playAccountId,
        'p',
      );
      expect(registered, isNot(fresh));
    });
  });

  group('UserSettings', () {
    test('first-launch defaults', () {
      const s = UserSettings();
      expect(s.themeMode, ThemeMode.system);
      expect(s.localeOverride, isNull);
      expect(s.reversalsEnabled, isTrue);
      expect(s.hapticsEnabled, isTrue);
      expect(s.reminder, const ReminderSettings());
      expect(s.reminder.enabled, isFalse);
      expect(s.reminder.hour, 9);
      expect(s.reminder.minute, 0);
      expect(s.reduceMotion, isNull);
    });

    test('backup round trip; reduceMotion stays on the device', () {
      const s = UserSettings(
        themeMode: ThemeMode.dark,
        localeOverride: 'uk',
        reversalsEnabled: false,
        reminder: ReminderSettings(enabled: true, time: '21:45'),
        reduceMotion: true,
      );
      final json = s.toBackupJson();
      expect(json, {
        'theme': 'dark',
        'reversalsEnabled': false,
        'hapticsEnabled': true,
        'reminder': {'enabled': true, 'time': '21:45'},
        'localeOverride': 'uk',
      });
      expect(UserSettings.fromBackupJson(json, reduceMotion: true), s);
      expect(UserSettings.fromBackupJson(json).reduceMotion, isNull);
      expect(s.reminder.hour, 21);
      expect(s.reminder.minute, 45);
    });

    test('rejects bad locale, theme and time', () {
      Map<String, Object?> base() => const UserSettings().toBackupJson();
      expect(
        () => UserSettings.fromBackupJson(base()..['localeOverride'] = 'xx'),
        throwsFormatException,
      );
      expect(
        () => UserSettings.fromBackupJson(base()..['theme'] = 'sepia'),
        throwsFormatException,
      );
      expect(
        () => UserSettings.fromBackupJson(
          base()..['reminder'] = {'enabled': true, 'time': '24:00'},
        ),
        throwsFormatException,
      );
    });

    test('supported locales are the 12 app locales', () {
      expect(kSupportedLocales, hasLength(12));
      expect(kSupportedLocales.first, 'en');
    });
  });
}
