import 'package:taro_core/taro_core.dart';
import 'package:test/test.dart';

void main() {
  group('TaroCorePackage', () {
    test('barrel exports the package marker', () {
      expect(TaroCorePackage.name, 'taro_core');
    });

    test('describe mentions the package name', () {
      expect(TaroCorePackage.describe(), startsWith('taro_core'));
    });
  });
}
