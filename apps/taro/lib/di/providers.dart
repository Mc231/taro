import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/bootstrap/flavor_config.dart';
import 'package:taro/data/content/asset_content_repository.dart';
import 'package:taro_core/taro_core.dart';

/// The active [FlavorConfig]; overridden in `bootstrap()`.
final flavorConfigProvider = Provider<FlavorConfig>(
  (ref) => throw UnimplementedError('flavorConfigProvider is not overridden'),
);

/// The bundled-content adapter over `rootBundle` (Phase 5, RC26). One
/// instance, so the manifest and the parsed locales are cached app-wide.
final assetContentRepositoryProvider = Provider<AssetContentRepository>(
  (ref) => AssetContentRepository.fromBundle(rootBundle),
);

/// The [ContentRepository] port (02 §5).
final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ref.watch(assetContentRepositoryProvider),
);

/// The [CrisisResourcesRepository] port (RC25, RC81).
final crisisResourcesRepositoryProvider = Provider<CrisisResourcesRepository>(
  (ref) => ref.watch(assetContentRepositoryProvider).crisis,
);
