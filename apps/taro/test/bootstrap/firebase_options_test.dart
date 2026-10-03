import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/firebase_options_dev.dart' as dev;
import 'package:taro/firebase_options_prod.dart' as prod;
import 'package:taro/firebase_options_staging.dart' as staging;

/// The `flutterfire configure` output per flavor (Phase 10 Sprint 10.2,
/// RC36): dev and staging use `taro-app-dev`, prod uses `taro-app-prod`,
/// each with the flavor's bundle ID / application ID (02 §15).
void main() {
  final cases = <String, (FirebaseOptions, FirebaseOptions, String, String)>{
    'dev': (
      dev.DefaultFirebaseOptions.ios,
      dev.DefaultFirebaseOptions.android,
      'taro-app-dev',
      'com.vshyrochuk.taro.dev',
    ),
    'staging': (
      staging.DefaultFirebaseOptions.ios,
      staging.DefaultFirebaseOptions.android,
      'taro-app-dev',
      'com.vshyrochuk.taro.stg',
    ),
    'prod': (
      prod.DefaultFirebaseOptions.ios,
      prod.DefaultFirebaseOptions.android,
      'taro-app-prod',
      'com.vshyrochuk.taro',
    ),
  };

  for (final MapEntry(key: flavor, value: c) in cases.entries) {
    test('$flavor: project and bundle ID', () {
      final (ios, android, project, bundleId) = c;
      expect(ios.projectId, project);
      expect(android.projectId, project);
      expect(ios.iosBundleId, bundleId);
      expect(ios.appId, contains(':ios:'));
      expect(android.appId, contains(':android:'));
    });
  }

  test('currentPlatform follows the target platform', () {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(
      prod.DefaultFirebaseOptions.currentPlatform,
      same(prod.DefaultFirebaseOptions.ios),
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(
      dev.DefaultFirebaseOptions.currentPlatform,
      same(dev.DefaultFirebaseOptions.android),
    );
  });
}
