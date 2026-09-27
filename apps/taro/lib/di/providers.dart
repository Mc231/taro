import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taro/bootstrap/flavor_config.dart';

/// The active [FlavorConfig]; overridden in `bootstrap()`.
final flavorConfigProvider = Provider<FlavorConfig>(
  (ref) => throw UnimplementedError('flavorConfigProvider is not overridden'),
);
