import 'package:flutter_test/flutter_test.dart';
import 'package:taro/bootstrap/flavor_config.dart';

import '../helpers/config_files.dart';

/// Google's published sample AdMob IDs (06 §8: debug and CI builds must
/// never request real ads).
const _googleTestPublisher = 'ca-app-pub-3940256099942544';

const _googleTestIds = {
  'ios.appId': 'ca-app-pub-3940256099942544~1458002511',
  'ios.banner': 'ca-app-pub-3940256099942544/2934735716',
  'ios.rewarded': 'ca-app-pub-3940256099942544/1712485313',
  'android.appId': 'ca-app-pub-3940256099942544~3347511713',
  'android.banner': 'ca-app-pub-3940256099942544/6300978111',
  'android.rewarded': 'ca-app-pub-3940256099942544/5224354917',
};

Map<String, String> _ids(FlavorConfig c) => {
  'ios.appId': c.admobIos.appId,
  'ios.banner': c.admobIos.banner,
  'ios.rewarded': c.admobIos.rewarded,
  'android.appId': c.admobAndroid.appId,
  'android.banner': c.admobAndroid.banner,
  'android.rewarded': c.admobAndroid.rewarded,
};

void main() {
  for (final name in ['dev', 'staging']) {
    test('$name uses Google test ad IDs only', () {
      final config = FlavorConfig.fromJson(readConfigFile(name));
      expect(_ids(config), _googleTestIds);
    });
  }

  test('prod never ships Google test ad IDs', () {
    final config = FlavorConfig.fromJson(readConfigFile('prod'));
    for (final id in _ids(config).values) {
      expect(id, isNot(startsWith(_googleTestPublisher)));
    }
  });
}
