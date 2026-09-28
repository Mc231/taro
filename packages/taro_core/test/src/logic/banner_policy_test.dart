import 'dart:io';

import 'package:test/test.dart';

import 'logic_support.dart';

/// The rows of GLOSSARY §10: `(S-ID, banner screen ID or null)`.
List<(String, String?)> _glossaryScreens() {
  final lines = File('../../docs/specs/GLOSSARY.md').readAsLinesSync();
  final row = RegExp(r'^\| (S\d\d) \|.*\| `?([a-z_]+|—)`? \|$');
  return [
    for (final line in lines)
      if (row.firstMatch(line) case final m?)
        (m[1]!, m[2] == '—' ? null : m[2]),
  ];
}

const _owned = Entitlement(
  removeAds: EntitlementState.owned,
  source: EntitlementSource.store,
);

void main() {
  final screens = _glossaryScreens();

  test('GLOSSARY lists S01–S33 and exactly the allow-list banners', () {
    expect(screens, hasLength(33));
    expect({for (final (_, b) in screens) ?b}, kBannerAllowList);
    expect(
      {
        for (final (s, b) in screens)
          if (b != null) s,
      },
      {'S05', 'S14', 'S16'},
    );
  });

  test('BannerScreen mirrors kBannerAllowList', () {
    expect({for (final s in BannerScreen.values) s.id}, kBannerAllowList);
    expect(BannerScreen.fromId('journal_list'), BannerScreen.journalList);
    expect(BannerScreen.fromId('S09'), isNull);
  });

  group('BannerPolicy.shouldShow truth table', () {
    // Each condition of the formula, as a way to break it.
    final breakers = <String, bool Function(String)>{
      'ads.enabled off': (id) => BannerPolicy.shouldShow(
        id,
        config: RemoteConfig.defaults.copyWith(adsEnabled: false),
        entitlement: Entitlement.unknown,
        canRequestAds: true,
        completedReadings: 1,
      ),
      'ads.bannerEnabled off': (id) => BannerPolicy.shouldShow(
        id,
        config: RemoteConfig.defaults.copyWith(adsBannerEnabled: false),
        entitlement: Entitlement.unknown,
        canRequestAds: true,
        completedReadings: 1,
      ),
      'not in ads.bannerScreens': (id) => BannerPolicy.shouldShow(
        id,
        config: RemoteConfig.defaults.copyWith(adsBannerScreens: const []),
        entitlement: Entitlement.unknown,
        canRequestAds: true,
        completedReadings: 1,
      ),
      'Remove Ads owned': (id) => BannerPolicy.shouldShow(
        id,
        config: RemoteConfig.defaults,
        entitlement: _owned,
        canRequestAds: true,
        completedReadings: 1,
      ),
      'cannot request ads': (id) => BannerPolicy.shouldShow(
        id,
        config: RemoteConfig.defaults,
        entitlement: Entitlement.unknown,
        canRequestAds: false,
        completedReadings: 1,
      ),
      'below bannerMinCompletedReadings': (id) => BannerPolicy.shouldShow(
        id,
        config: RemoteConfig.defaults,
        entitlement: Entitlement.unknown,
        canRequestAds: true,
        completedReadings: 0,
      ),
    };

    bool allTrue(String id) => BannerPolicy.shouldShow(
      id,
      config: RemoteConfig.defaults,
      entitlement: Entitlement.unknown,
      canRequestAds: true,
      completedReadings: 1,
    );

    for (final (screen, bannerId) in screens) {
      // A screen without a banner ID is asked for by its S-ID.
      final id = bannerId ?? screen;
      test('$screen (${bannerId ?? 'no banner'}): shows only if allowed', () {
        expect(allTrue(id), bannerId != null);
        for (final MapEntry(key: name, value: check) in breakers.entries) {
          expect(check(id), isFalse, reason: '$screen with $name');
        }
      });
    }

    test('an ID outside the allow-list never shows, even if configured', () {
      expect(
        BannerPolicy.shouldShow(
          'reading',
          config: RemoteConfig.defaults.copyWith(
            adsBannerScreens: const ['reading', 'home'],
          ),
          entitlement: Entitlement.unknown,
          canRequestAds: true,
          completedReadings: 5,
        ),
        isFalse,
      );
    });

    test('bannerScreens narrows the allow-list; notOwned shows', () {
      final config = RemoteConfig.defaults.copyWith(
        adsBannerScreens: const ['home'],
        adsBannerMinCompletedReadings: 0,
      );
      const notOwned = Entitlement(
        removeAds: EntitlementState.notOwned,
        source: EntitlementSource.store,
      );
      bool show(String id) => BannerPolicy.shouldShow(
        id,
        config: config,
        entitlement: notOwned,
        canRequestAds: true,
        completedReadings: 0,
      );
      expect(show('home'), isTrue);
      expect(show('journal_list'), isFalse);
      expect(show('learn_library'), isFalse);
    });
  });
}
