import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/content/asset_crisis_resources_repository.dart';
import 'package:taro/data/content/content_asset_store.dart';
import 'package:taro/data/content/content_assets.dart';
import 'package:taro_core/taro_core.dart';

// The allowed exception: taro_core's contract suites by relative path.
import '../../../../../packages/taro_core/test/contracts/content_contracts.dart';
import '../../../../../packages/taro_core/test/contracts/contract_support.dart';
import 'disk_asset_bundle.dart';

AssetCrisisResourcesRepository _repo([DiskAssetBundle? bundle]) =>
    AssetCrisisResourcesRepository(
      ContentAssetStore(bundle ?? DiskAssetBundle()),
    );

void main() {
  runCrisisResourcesRepositoryContract(_repo);

  group('bundled directory', () {
    test('covers the 05 §4.2 minimum set and every app locale', () async {
      final directory = expectOk(await _repo().directory());
      expect(
        directory.countries.keys,
        containsAll([
          'US', 'GB', 'IE', 'CA', 'AU', 'DE', 'FR', 'ES', 'IT', 'NL', //
          'JP', 'KR', 'TR', 'UA', 'BR', 'PT',
        ]),
      );
      expect(directory.localeFallback.keys, hasLength(12));
      expect(directory.international.single.url, contains('findahelpline'));
    });

    test('lookup: country, then locale default, then international', () async {
      final crisis = _repo();
      final us = expectOk(await crisis.select(country: 'us'));
      expect(us.first.phone, '988');
      expect(us, hasLength(2));

      final nl = expectOk(await crisis.select(country: 'NL'));
      expect(nl, hasLength(2)); // 113 only (0800-0113 removed 2026-10-06)
      expect(nl.first.phone, '113');
      expect(nl.last.url, contains('findahelpline'));

      final byLocale = expectOk(
        await crisis.select(country: 'ZZ', locale: 'pt-PT'),
      );
      expect(byLocale.first.phone, '188'); // pt → BR (localeFallback)

      final uk = expectOk(await crisis.select(locale: 'uk'));
      expect(uk.first.phone, '116 123');

      final ar = expectOk(await crisis.select(locale: 'ar'));
      expect(ar, hasLength(1)); // ar → international only

      for (final country in ['DE', 'FR', 'JP', null]) {
        final selected = expectOk(await crisis.select(country: country));
        expect(selected.length, lessThanOrEqualTo(CrisisDirectory.maxResults));
      }
    });

    test('unverified entries parse as stale (epoch)', () async {
      final raw =
          jsonDecode(
                File(
                  ContentAssets.file(ContentAssets.crisisResourcesFile),
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final directory = parseCrisisDirectory(raw);
      final all = [
        ...directory.countries.values.expand((l) => l),
        ...directory.international,
      ];
      final unverified =
          ((raw['international']! as List).first as Map)['verifiedAt'] == null;
      if (unverified) {
        expect(
          directory.international.first.verifiedAt,
          kUnverifiedCrisisResourceAt,
        );
      }
      expect(all, everyElement(isA<CrisisResource>()));

      final verified = parseCrisisDirectory({
        'countries': <String, Object?>{},
        'localeFallback': <String, Object?>{},
        'international': [
          {
            'name': 'X',
            'url': 'https://example.org',
            'languages': <Object?>[],
            'verifiedAt': '2026-09-01T00:00:00Z',
          },
        ],
      });
      expect(
        verified.international.single.verifiedAt,
        DateTime.utc(2026, 9),
      );
    });

    test('a corrupt or missing file is a StorageFailure', () async {
      final key = ContentAssets.file(ContentAssets.crisisResourcesFile);
      final tampered = _repo(
        DiskAssetBundle(overrides: {key: utf8.encode('{}')}),
      );
      expect(expectErr(await tampered.directory()), const Failure.storage());
      expect(expectErr(await tampered.select()), const Failure.storage());

      final missing = _repo(DiskAssetBundle(missing: {key}));
      expect(expectErr(await missing.directory()), const Failure.storage());
    });

    test('the directory is parsed once', () async {
      final bundle = DiskAssetBundle();
      final crisis = _repo(bundle);
      final first = expectOk(await crisis.directory());
      expect(expectOk(await crisis.directory()), same(first));
      expect(
        bundle.loads[ContentAssets.file(ContentAssets.crisisResourcesFile)],
        1,
      );
    });
  });
}
