import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/di/providers.dart';

void main() {
  test('flavorConfigProvider must be overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      () => container.read(flavorConfigProvider),
      throwsA(anything),
    );
  });
}
