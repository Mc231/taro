import 'package:flutter_test/flutter_test.dart';
import 'package:taro/bootstrap/flavor_config.dart';

import '../helpers/config_files.dart';

void main() {
  group('config/*.json', () {
    const expectedApi = {
      'dev': 'http://localhost:8787',
      'staging': 'https://api-staging.taro.vshyrochuk.com',
      'prod': 'https://api.taro.vshyrochuk.com',
    };

    for (final name in configNames) {
      test('$name.json parses into FlavorConfig', () {
        final json = readConfigFile(name);
        final config = FlavorConfig.fromJson(json);
        expect(config.flavor.name, name);
        expect(config.apiBaseUrl, expectedApi[name]);
        expect(config.privacyPolicyUrl, 'https://taro.vshyrochuk.com/privacy');
        expect(config.termsUrl, 'https://taro.vshyrochuk.com/terms');
        expect(config.supportEmail, isNotEmpty);
        expect(config.universalLinkHost, 'taro.vshyrochuk.com');
        expect(config.playCloudProjectNumber, isNotEmpty);
        expect(config.admobIos.appId, isNotEmpty);
        expect(config.admobAndroid.rewarded, isNotEmpty);
        expect(config.isProd, name == 'prod');
      });

      test('$name.json has exactly the 02 §15 keys', () {
        expect(readConfigFile(name).keys.toSet(), {
          ...FlavorConfig.dartDefines.keys,
        });
      });

      test('$name.json values are all strings', () {
        // --dart-define-from-file only accepts flat primitive values.
        expect(readConfigFile(name).values, everyElement(isA<String>()));
      });
    }

    test('only dev talks plain http', () {
      for (final name in configNames) {
        final url = FlavorConfig.fromJson(readConfigFile(name)).apiBaseUrl;
        expect(url.startsWith('https://'), name != 'dev', reason: name);
      }
    });
  });

  group('FlavorConfig.fromJson', () {
    test('rejects an unknown flavor', () {
      expect(
        () => FlavorConfig.fromJson({'flavor': 'qa'}),
        throwsFormatException,
      );
    });

    test('rejects a missing flavor', () {
      expect(() => FlavorConfig.fromJson({}), throwsFormatException);
    });

    test('missing values become empty strings', () {
      final config = FlavorConfig.fromJson({'flavor': 'dev'});
      expect(config.apiBaseUrl, isEmpty);
      expect(config.admobIos.banner, isEmpty);
    });
  });

  group('FlavorConfig.fromDefines', () {
    test('uses the entrypoint flavor when no config file was given', () {
      final config = FlavorConfig.fromDefines(
        Flavor.staging,
        defines: const {'flavor': ''},
      );
      expect(config.flavor, Flavor.staging);
    });

    test('accepts the matching config file', () {
      final defines = readConfigFile('dev').cast<String, String>();
      final config = FlavorConfig.fromDefines(Flavor.dev, defines: defines);
      expect(config.apiBaseUrl, 'http://localhost:8787');
    });

    test('throws when the config file is for another flavor', () {
      final defines = readConfigFile('prod').cast<String, String>();
      expect(
        () => FlavorConfig.fromDefines(Flavor.dev, defines: defines),
        throwsStateError,
      );
    });

    test('defaults to the compile-time defines', () {
      // `flutter test` runs without --dart-define-from-file.
      expect(FlavorConfig.fromDefines(Flavor.prod).flavor, Flavor.prod);
    });
  });
}
