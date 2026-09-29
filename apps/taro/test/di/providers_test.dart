import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro/data/content/asset_content_repository.dart';
import 'package:taro/data/content/asset_crisis_resources_repository.dart';
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

  test('content ports share one bundled-content adapter', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final adapter = container.read(assetContentRepositoryProvider);
    expect(container.read(contentRepositoryProvider), same(adapter));
    expect(
      container.read(crisisResourcesRepositoryProvider),
      isA<AssetCrisisResourcesRepository>().having(
        (c) => c,
        'crisis',
        same(adapter.crisis),
      ),
    );
    expect(adapter, isA<AssetContentRepository>());
  });
}
