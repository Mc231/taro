import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:taro/services/device/package_info_app_info.dart';
import 'package:taro_core/taro_core.dart';

import '../../../../../packages/taro_core/test/contracts/contracts.dart';

final class _Ios extends Fake implements IosDeviceInfo {
  _Ios(this.model, this.systemVersion);

  @override
  final String model;

  @override
  final String systemVersion;
}

final class _Version extends Fake implements AndroidBuildVersion {
  _Version(this.release);

  @override
  final String release;
}

final class _Android extends Fake implements AndroidDeviceInfo {
  _Android(String release) : version = _Version(release);

  @override
  final AndroidBuildVersion version;
}

final class _Devices extends Fake implements DeviceInfoPlugin {
  _Devices({IosDeviceInfo? ios, AndroidDeviceInfo? android})
    : _ios = ios,
      _android = android;

  final IosDeviceInfo? _ios;
  final AndroidDeviceInfo? _android;

  @override
  Future<IosDeviceInfo> get iosInfo async => _ios!;

  @override
  Future<AndroidDeviceInfo> get androidInfo async => _android!;
}

Future<PackageInfo> _package({
  String version = '1.2.0',
  String build = '34',
}) async => PackageInfo(
  appName: 'Taro',
  packageName: 'com.vshyrochuk.taro',
  version: version,
  buildNumber: build,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PackageInfoAppInfo> ios({String model = 'iPhone'}) =>
      PackageInfoAppInfo.load(
        packageInfo: _package,
        deviceInfo: _Devices(ios: _Ios(model, '18.1')),
        targetPlatform: TargetPlatform.iOS,
      );

  Future<PackageInfoAppInfo> android({
    double shortestSide = 411,
    String release = '15',
  }) => PackageInfoAppInfo.load(
    packageInfo: _package,
    deviceInfo: _Devices(android: _Android(release)),
    targetPlatform: TargetPlatform.android,
    shortestSide: shortestSide,
  );

  group('PackageInfoAppInfo', () {
    late PackageInfoAppInfo iosInfo;
    late PackageInfoAppInfo androidInfo;

    setUpAll(() async {
      iosInfo = await ios();
      androidInfo = await android();
    });

    group('iOS', () => runAppInfoContract(() => iosInfo));
    group('Android', () => runAppInfoContract(() => androidInfo));

    test('reads iOS facts', () async {
      expect(iosInfo.version, '1.2.0');
      expect(iosInfo.buildNumber, '34');
      expect(iosInfo.platform, AppPlatform.ios);
      expect(iosInfo.osVersion, '18.1');
      expect(iosInfo.deviceModelClass, 'phone');
      expect((await ios(model: 'iPad')).deviceModelClass, 'tablet');
    });

    test('reads Android facts; tablets by shortest side', () async {
      expect(androidInfo.platform, AppPlatform.android);
      expect(androidInfo.osVersion, '15');
      expect(androidInfo.deviceModelClass, 'phone');
      expect((await android(shortestSide: 600)).deviceModelClass, 'tablet');
      expect((await android(release: '')).osVersion, 'unknown');
    });

    test('the default size comes from the first view', () async {
      final info = await PackageInfoAppInfo.load(
        packageInfo: _package,
        deviceInfo: _Devices(android: _Android('14')),
        targetPlatform: TargetPlatform.android,
      );
      final side = PackageInfoAppInfo.firstViewShortestSide();
      expect(side, greaterThan(0));
      expect(
        info.deviceModelClass,
        side >= PackageInfoAppInfo.tabletShortestSide ? 'tablet' : 'phone',
      );
    });

    test('the defaults use the plugins and the running platform', () async {
      PackageInfo.setMockInitialValues(
        appName: 'Taro',
        packageName: 'com.vshyrochuk.taro',
        version: '0.1.0',
        buildNumber: '1',
        buildSignature: '',
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final info = await PackageInfoAppInfo.load(
        deviceInfo: _Devices(ios: _Ios('iPhone', '17.0')),
      );
      expect(info.version, '0.1.0');
      expect(info.platform, AppPlatform.ios);
    });

    test('the default device info reads the plugin channel', () async {
      const channel = MethodChannel('dev.fluttercommunity.plus/device_info');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => _iosMap);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final info = await PackageInfoAppInfo.load(
        packageInfo: _package,
        targetPlatform: TargetPlatform.iOS,
      );
      expect(info.osVersion, '26.0');
      expect(info.deviceModelClass, 'tablet');
    });

    test('normalises versions and build numbers', () {
      expect(PackageInfoAppInfo.marketingVersion('1.2.0-dev+5'), '1.2.0');
      expect(PackageInfoAppInfo.marketingVersion(' 2.0.1 '), '2.0.1');
      expect(PackageInfoAppInfo.marketingVersion('beta'), '0.0.0');
      expect(PackageInfoAppInfo.buildNumberOf('34'), '34');
      expect(PackageInfoAppInfo.buildNumberOf('34a'), '0');
    });
  });
}

const Map<String, Object?> _iosMap = {
  'name': 'iPad',
  'systemName': 'iPadOS',
  'systemVersion': '26.0',
  'model': 'iPad',
  'modelName': 'iPad Pro',
  'localizedModel': 'iPad',
  'identifierForVendor': null,
  'freeDiskSize': 1,
  'totalDiskSize': 2,
  'isPhysicalDevice': true,
  'isiOSAppOnMac': false,
  'isiOSAppOnVision': false,
  'physicalRamSize': 8,
  'availableRamSize': 4,
  'utsname': {
    'sysname': 'Darwin',
    'nodename': 'ipad',
    'release': '25',
    'version': '25',
    'machine': 'iPad16,3',
  },
};
