/// The 02 §2.1 dependency tables as data (RC95: 3 packages + the app).
library;

/// Riverpod packages (banned in `taro_core`, `taro_ui`, `data/`,
/// `services/`).
const riverpodPackages = {
  'riverpod',
  'flutter_riverpod',
  'hooks_riverpod',
  'riverpod_annotation',
};

/// I/O and platform packages `taro_core` may not use (pure Dart).
const ioPackages = {
  'dio',
  'http',
  'drift',
  'drift_flutter',
  'sqlite3',
  'flutter_secure_storage',
  'shared_preferences',
  'path_provider',
  'google_mobile_ads',
  'app_tracking_transparency',
  'connectivity_plus',
  'device_info_plus',
  'package_info_plus',
  'file_picker',
  'share_plus',
  'in_app_review',
  'flutter_timezone',
  'flutter_local_notifications',
};

/// Vendor SDKs a `features/` folder may not import (02 §2.1, 06 §6.2).
const featureVendorPackages = {
  'google_mobile_ads',
  'drift',
  'drift_flutter',
  'dio',
  'http',
  'flutter_secure_storage',
  'app_tracking_transparency',
  'taro_attestation',
};

/// SDK libraries `taro_core` may not import.
const coreForbiddenDartLibraries = {
  'dart:ui',
  'dart:io',
  'dart:html',
  'dart:ffi',
  'dart:js',
  'dart:js_interop',
};

/// The taro packages of the workspace (package name → role).
const taroPackages = {'taro', 'taro_core', 'taro_ui', 'taro_attestation'};

/// Why package [importer] may not depend on [dependency], or `null`.
///
/// [dependency] is a package name or a `dart:` library.
String? packageRuleViolation(String importer, String dependency) {
  switch (importer) {
    case 'taro_core':
      if (dependency.startsWith('dart:')) {
        return coreForbiddenDartLibraries.contains(dependency)
            ? 'taro_core is pure Dart: no $dependency'
            : null;
      }
      if (dependency == 'flutter' ||
          dependency.startsWith('flutter_') ||
          dependency == 'sky_engine') {
        return 'taro_core is pure Dart: no Flutter ($dependency)';
      }
      if (ioPackages.contains(dependency) ||
          dependency.startsWith('firebase_') ||
          dependency.startsWith('in_app_purchase')) {
        return 'taro_core may not use the I/O package $dependency';
      }
      if (riverpodPackages.contains(dependency)) {
        return 'taro_core may not use Riverpod ($dependency)';
      }
      if (taroPackages.contains(dependency) && dependency != 'taro_core') {
        return 'taro_core may not depend on $dependency';
      }
    case 'taro_ui':
      if (riverpodPackages.contains(dependency)) {
        return 'taro_ui may not use Riverpod ($dependency)';
      }
      if (taroPackages.contains(dependency) && dependency != 'taro_ui') {
        return 'taro_ui may not depend on $dependency '
            '(components take localised strings)';
      }
    case 'taro_attestation':
      if (taroPackages.contains(dependency) && dependency != importer) {
        return 'taro_attestation may not depend on any taro package '
            '($dependency)';
      }
  }
  return null;
}

/// The rule zone of an `apps/taro/lib`-relative path, or `null` when the
/// file is unrestricted (composition root and root files).
String? zoneOf(String libPath) {
  final parts = libPath.split('/');
  if (parts.length < 2) return null;
  switch (parts.first) {
    case 'data':
      return parts[1] == 'content' && parts.length > 2
          ? 'data/content'
          : 'data';
    case 'services':
      return parts[1] == 'presentation' && parts.length > 2
          ? 'services/presentation'
          : 'services';
    case 'features':
      return parts.length > 2 ? 'features/${parts[1]}' : 'features';
    case 'l10n':
    case 'app_state':
    case 'common':
      return parts.first;
  }
  return null;
}

bool _under(String path, String folder) => path.startsWith('$folder/');

/// Why [source] may not import [target] (both `apps/taro/lib`-relative), or
/// `null` when the folder table allows it.
String? folderRuleViolation(String source, String target) {
  final zone = zoneOf(source);
  if (zone == null) return null;
  final top = target.contains('/') ? '${target.split('/').first}/' : target;
  switch (zone) {
    case 'data/content':
      if (!_under(target, 'data/content')) {
        return 'data/content/ may import only data/content/ (and taro_core), '
            'not $top';
      }
    case 'data':
      if (!_under(target, 'data')) return 'data/ must not import $top';
    case 'services/presentation':
      if (!_under(target, 'services')) {
        return 'services/presentation/ must not import $top';
      }
    case 'services':
      if (_under(target, 'services/presentation')) {
        return 'services/ must not import services/presentation/ '
            '(only bootstrap/ and di/ do)';
      }
      if (!_under(target, 'services')) {
        return 'services/ must not import $top '
            '(reach data only through taro_core ports)';
      }
    case 'l10n':
      if (!_under(target, 'l10n')) return 'l10n/ must not import $top';
    case 'app_state':
      if (!_under(target, 'app_state') && !_under(target, 'di')) {
        return 'app_state/ may import only app_state/ and di/, not $top';
      }
    case 'common':
      const allowed = ['common', 'l10n', 'app_state', 'di'];
      if (!allowed.any((folder) => _under(target, folder))) {
        return 'common/ may import only common/, l10n/, app_state/ and di/, '
            'not $top';
      }
    default: // features/<f>
      final own = zone == 'features' ? null : zone;
      final ok =
          (own != null && _under(target, own)) ||
          _under(target, 'l10n') ||
          _under(target, 'app_state') ||
          _under(target, 'common') ||
          target == 'di/providers.dart' ||
          target == 'routing/routes.dart';
      if (!ok) {
        if (_under(target, 'features')) {
          return '$zone/ must not import another feature ($target)';
        }
        return '$zone/ must not import $target (features use taro_core '
            'ports, di/providers.dart, app_state/, routing/routes.dart, '
            'common/ and l10n/ only)';
      }
  }
  return null;
}

/// Why an `apps/taro/lib` file in [zone] may not import [package], or
/// `null`.
String? folderPackageViolation(String? zone, String package) {
  if (zone == null) return null;
  final riverpod = riverpodPackages.contains(package);
  switch (zone) {
    case 'data':
    case 'data/content':
      if (package == 'taro_ui' || riverpod) {
        return '$zone/ must not import $package';
      }
    case 'services':
      if (package == 'taro_ui' || riverpod) {
        return 'services/ must not import $package';
      }
    case 'services/presentation':
      if (riverpod) return 'services/presentation/ must not import $package';
    case 'l10n':
      if (taroPackages.contains(package)) {
        return 'l10n/ must not import the taro package $package';
      }
    case 'app_state':
    case 'common':
      break;
    default: // features/<f>
      if (featureVendorPackages.contains(package) ||
          package.startsWith('firebase_') ||
          package.startsWith('in_app_purchase') ||
          package.startsWith('sqlite3')) {
        return '$zone/ must not import the vendor SDK $package '
            '(use a taro_core port)';
      }
  }
  return null;
}

/// Test-support folders `apps/taro/test/**` may import by relative path
/// (02 §2.1; RC95).
const appTestHelperFolders = [
  'packages/taro_core/test/fakes/',
  'packages/taro_core/test/contracts/',
  'packages/taro_ui/test/helpers/',
];
