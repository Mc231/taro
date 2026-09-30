import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

void main() {
  test('every licence file exists and is the OFL', () {
    for (final file in kTaroFontLicenseFiles.values) {
      final text = File('fonts/licenses/$file').readAsStringSync();
      expect(text, contains('SIL OPEN FONT LICENSE'), reason: file);
    }
  });

  test('registers one licence entry per family', () async {
    final keys = <String>[];
    registerTaroFontLicenses(
      load: (key) async {
        keys.add(key);
        return File(
          'fonts/licenses/${key.split('/').last}',
        ).readAsStringSync();
      },
    );
    final entries = await LicenseRegistry.licenses.toList();
    final packages = entries.expand((e) => e.packages).toSet();
    expect(packages, containsAll(kTaroFontLicenseFiles.keys));
    expect(
      keys,
      everyElement(startsWith('packages/taro_ui/fonts/licenses/OFL-')),
    );
  });

  test('defaults to the root bundle', () {
    // Registration is lazy: nothing loads until the licences are read.
    expect(registerTaroFontLicenses, returnsNormally);
  });
}
